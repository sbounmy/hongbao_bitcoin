require "open-uri"
require "nokogiri"

module Substack
  class Feed
    FEED_URL = "https://sbounmy.substack.com/feed"
    CACHE_KEY = "substack_feed_items"
    CACHE_DURATION = 4.hours

    def self.call
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_DURATION) do
        new.fetch_all_items
      end
    end

    def fetch_all_items
      # Use URI.open which handles SSL properly with system certificates
      response = URI.open(FEED_URL, read_timeout: 10, open_timeout: 10).read
      doc = Nokogiri::XML(response)

      doc.xpath("//item").map do |item|
        {
          title: item.at_xpath("title")&.text,
          link: item.at_xpath("link")&.text,
          description: item.at_xpath("description")&.text&.strip,
          published_at: Time.parse(item.at_xpath("pubDate")&.text),
          image_url: item.at_xpath("enclosure")&.attr("url"),
          author: item.at_xpath("dc:creator", "dc" => "http://purl.org/dc/elements/1.1/")&.text || "Stephane Bounmy"
        }
      end
    rescue => e
      Rails.logger.error "Failed to fetch Substack feed: #{e.message}"
      [ { title: "Error fetching update", description: e.message } ]
    end
  end
end
