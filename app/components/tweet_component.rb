class TweetComponent < ApplicationComponent
  attr_reader :tweet_id, :author_name, :author_handle, :tweet_text, :date, :url, :media_urls, :likes, :profile_image, :verified

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
      @profile_image = tweet_data[:profile_image] || default_profile_image
      @verified = tweet_data[:verified] || false
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

  def twitter_logo
    # Twitter/X logo SVG
    %(<svg viewBox="0 0 24 24" class="w-5 h-5 fill-current" aria-hidden="true">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>).html_safe
  end
end
