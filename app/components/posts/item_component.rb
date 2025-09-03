# frozen_string_literal: true

module Posts
  class ItemComponent < ViewComponent::Base
    with_collection_parameter :post

    def initialize(post:)
      @post = post
    end

    private

    attr_reader :post

    def title
      post.data.title
    end

    def description
      post.data.description
    end

    def date
      post.data.date
    end

    def author
      post.data.author
    end

    def image
      post.data.image
    end

    def url
      post.request_path
    end

    def formatted_date
      return nil unless date
      date.strftime("%b %d, %Y")
    end

    def has_image?
      image.present?
    end

    def has_metadata?
      date.present? || author.present?
    end
  end
end
