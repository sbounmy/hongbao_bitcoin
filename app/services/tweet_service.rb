require "net/http"
require "json"

class TweetService
  CACHE_EXPIRY = 1.month
  SYNDICATION_API_URL = "https://cdn.syndication.twimg.com/tweet-result"

  def self.fetch(tweet_id)
    Rails.cache.fetch("tweet/#{tweet_id}", expires_in: CACHE_EXPIRY) do
      fetch_from_twitter_api(tweet_id)
    end
  end

  def self.fetch_multiple(tweet_ids)
    tweet_ids.map { |id| fetch(id) }.compact
  end

  private

  def self.fetch_from_twitter_api(tweet_id)
    token = generate_token(tweet_id)
    uri = URI("#{SYNDICATION_API_URL}?id=#{tweet_id}&lang=en&token=#{token}")

    begin
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        data = JSON.parse(response.body)

        # Check if we got an empty response
        if data.empty?
          Rails.logger.error "Empty response for tweet #{tweet_id}"
          return fallback_data(tweet_id)
        end

        parse_tweet_data(data)
      else
        Rails.logger.error "Failed to fetch tweet #{tweet_id}: HTTP #{response.code}"
        fallback_data(tweet_id)
      end
    rescue => e
      Rails.logger.error "Error fetching tweet #{tweet_id}: #{e.message}"
      fallback_data(tweet_id)
    end
  end

  def self.generate_token(tweet_id)
    # Port of react-tweet's getToken function
    # ((Number(id) / 1e15) * Math.PI).toString(36).replace(/(0+|\.)/g, '')
    number = (tweet_id.to_f / 1e15 * Math::PI)

    # In JavaScript, toString(36) on a float gives something like "4p0.ieqqniid"
    # Ruby doesn't have this, so we approximate it
    integer_part = number.to_i.to_s(36)

    # For the fractional part, we convert it to a string of base-36 digits
    fractional_part = number - number.to_i
    frac_str = ""
    f = fractional_part
    8.times do  # Limit precision to match JavaScript
      f *= 36
      digit = f.to_i
      frac_str += digit.to_s(36)
      f -= digit
    end

    # Combine and remove zeros and dots as in the JS version
    full_str = "#{integer_part}.#{frac_str}"
    full_str.gsub(/0+|\./, "")
  end

  def self.parse_tweet_data(data)
    # Handle the actual syndication API response format
    user = data["user"] || {}

    {
      id: data["id_str"],
      author_name: user["name"],
      author_handle: user["screen_name"],
      tweet_text: data["text"] || data["full_text"],
      date: format_date(data["created_at"]),
      url: "https://twitter.com/#{user["screen_name"]}/status/#{data["id_str"]}",
      profile_image: user["profile_image_url_https"]&.gsub("_normal", "_400x400"),
      verified: user["verified"] || user["is_blue_verified"] || false,
      media_urls: extract_media_urls(data),
      likes: data["favorite_count"],
      retweets: data["retweet_count"]
    }
  end

  def self.extract_media_urls(data)
    # The syndication API provides photos directly as an array
    if data["photos"] && data["photos"].is_a?(Array) && !data["photos"].empty?
      return data["photos"].map { |photo| photo["url"] }
    end

    # Fallback to checking entities (shouldn't be needed with syndication API)
    media_array = data.dig("extended_entities", "media") ||
                  data.dig("entities", "media") ||
                  data.dig("legacy", "entities", "media") ||
                  []

    return [] if media_array.empty?

    media_array.map { |m| m["media_url_https"] || m["media_url"] }.compact
  end

  def self.format_date(date_string)
    return "" unless date_string
    Time.parse(date_string).strftime("%B %-d, %Y")
  rescue
    date_string
  end

  def self.fallback_data(tweet_id)
    {
      id: tweet_id,
      author_name: "Twitter User",
      author_handle: "twitter",
      tweet_text: "Loading tweet...",
      date: "",
      url: "https://twitter.com/i/status/#{tweet_id}",
      profile_image: nil,
      verified: false,
      media_urls: [],
      likes: 0,
      retweets: 0
    }
  end
end
