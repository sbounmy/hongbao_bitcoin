# frozen_string_literal: true

module Contents
  module Products
    class JsonLdComponent < ::JsonLdComponent
      def initialize(product:, **options)
        @product = product
        super(**options)
      end

      private

      def schema_type
        "Product"
      end

      def specific_structure
        {
          name:,
          image:,
          description:,
          brand:,
          offers:
        }
      end

      def name
        @product.title
      end

      def image
        @product.image.attached? ? helpers.url_for(@product.image) : nil
      end

      def description
        @product.description
      end

      def brand
        {
          "@type": "Brand",
          name: @product.shop
        }
      end

      def offers
        {
          "@type": "Offer",
          price: @product.price,
          priceCurrency: currency,
          availability:,
          url: product_url
        }
      end

      def currency
        @product.currency || "USD"
      end

      def availability
        "https://schema.org/InStock"
      end

      def product_url
        @product.product_url || current_url
      end
    end
  end
end
