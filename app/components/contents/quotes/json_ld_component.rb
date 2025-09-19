# frozen_string_literal: true

module Contents
  module Quotes
    class JsonLdComponent < ::JsonLdComponent
      def initialize(quote:, **options)
        @quote = quote
        super(**options)
      end

      private

      def schema_type
        "Quotation"
      end

      def specific_structure
        {
          text:,
          author:,
          image:,
          url: current_url,
          datePublished: date_published,
          publisher:,
          mainEntityOfPage: main_entity,
          inLanguage: language
        }
      end

      def text
        @quote.text
      end

      def author
        {
          "@type": "Person",
          name: @quote.author
        }
      end

      def image
        @quote.best_image ? helpers.url_for(@quote.best_image) : helpers.image_url("bill_hongbao.jpg")
      end

      def date_published
        @quote.published_at&.iso8601 || @quote.created_at.iso8601
      end
    end
  end
end
