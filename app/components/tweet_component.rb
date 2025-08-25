class TweetComponent < ApplicationComponent
  include ActionView::Helpers::NumberHelper
  attr_reader :tweet_id, :author_name, :author_handle, :tweet_text, :date, :url, :media_urls, :likes, :retweets, :profile_image, :verified, :entities

  def initialize(tweet_id:)
    @tweet_id = tweet_id

    # Fetch tweet data from service
    tweet_data = TweetService.fetch(tweet_id)

    if tweet_data
      @author_name = tweet_data[:author_name]
      @author_handle = tweet_data[:author_handle]
      @tweet_text = tweet_data[:tweet_text]
      @date = tweet_data[:date]
      @url = tweet_data[:url]
      @media_urls = tweet_data[:media_urls] || []
      @likes = tweet_data[:likes]
      @retweets = tweet_data[:retweets]
      @profile_image = tweet_data[:profile_image] || default_profile_image
      @verified = tweet_data[:verified] || false
      @entities = tweet_data[:entities] || {}
    else
      # Fallback for unknown tweets
      @author_name = "Twitter User"
      @author_handle = "twitter"
      @tweet_text = "Loading tweet..."
      @date = ""
      @url = "https://twitter.com/i/status/#{tweet_id}"
      @media_urls = []
      @profile_image = default_profile_image
      @verified = false
      @retweets = 0
      @entities = {}
    end
  end

  private

  def default_profile_image
    "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ccircle cx='50' cy='50' r='50' fill='%23e5e7eb'/%3E%3C/svg%3E"
  end

  def formatted_date
    if date.is_a?(String)
      date
    else
      date.strftime("%B %-d, %Y")
    end
  end
  
  def formatted_time
    if date.is_a?(String)
      date
    else
      date.strftime("%-I:%M %p · %b %-d, %Y")
    end
  end
  
  def formatted_tweet_text
    text = tweet_text.dup
    
    # First, convert @mentions and #hashtags to placeholder tokens
    # so they don't interfere with URL replacements
    mention_map = {}
    hashtag_map = {}
    mention_counter = 0
    hashtag_counter = 0
    
    # Replace @mentions with placeholders
    text = text.gsub(/@(\w+)/) do |match|
      username = $1
      placeholder = "[[MENTION_#{mention_counter}]]"
      mention_map[placeholder] = "<a href='https://twitter.com/#{username}' target='_blank' rel='noopener' class='text-primary hover:underline'>@#{username}</a>"
      mention_counter += 1
      placeholder
    end
    
    # Replace #hashtags with placeholders
    text = text.gsub(/#(\w+)/) do |match|
      hashtag = $1
      placeholder = "[[HASHTAG_#{hashtag_counter}]]"
      hashtag_map[placeholder] = "<a href='https://twitter.com/hashtag/#{hashtag}' target='_blank' rel='noopener' class='text-primary hover:underline'>##{hashtag}</a>"
      hashtag_counter += 1
      placeholder
    end
    
    # Build a mapping of t.co URLs to their display text or removal
    url_replacements = {}
    
    # Process regular URLs (non-media)
    if entities["urls"]
      entities["urls"].each do |url_entity|
        display_url = url_entity["display_url"]
        
        if display_url
          # Just show the display URL as a link without @ prefix
          url_replacements[url_entity["url"]] = "<a href='#{url_entity["expanded_url"]}' target='_blank' rel='noopener' class='text-primary hover:underline'>#{display_url}</a>"
        end
      end
    end
    
    # Mark media URLs for removal (they're displayed separately as images)
    if entities["media"]
      entities["media"].each do |media|
        url_replacements[media["url"]] = ""
      end
    end
    
    # Replace all t.co URLs with their replacements
    url_replacements.each do |t_co_url, replacement|
      text = text.gsub(t_co_url, replacement)
    end
    
    # Clean up any remaining t.co URLs that weren't in entities (fallback)
    text = text.gsub(/https?:\/\/t\.co\/\w+/, "")
    
    # Clean up extra whitespace (but preserve line breaks)
    text = text.gsub(/[^\S\n]+/, " ").strip
    
    # Restore mentions
    mention_map.each do |placeholder, replacement|
      text = text.gsub(placeholder, replacement)
    end
    
    # Restore hashtags
    hashtag_map.each do |placeholder, replacement|
      text = text.gsub(placeholder, replacement)
    end
    
    text.html_safe
  end

  def twitter_logo
    # Twitter/X logo SVG
    %(<svg viewBox="0 0 24 24" class="w-5 h-5 fill-current" aria-hidden="true">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>).html_safe
  end
end
