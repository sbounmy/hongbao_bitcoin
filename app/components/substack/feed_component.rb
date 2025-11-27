module Substack
  class FeedComponent < ApplicationComponent
    def initialize(newsletter:)
      @newsletter = newsletter
    end

    private

    attr_reader :newsletter

    def title
      newsletter[:title]
    end

    def link
      newsletter[:link]
    end

    def description
      newsletter[:description]
    end

    def published_at
      newsletter[:published_at]
    end

    def image_url
      newsletter[:image_url]
    end

    def formatted_date
      return unless published_at
      published_at.strftime("%b %-d, %Y")
    rescue
      "Recently"
    end
  end
end
