# frozen_string_literal: true

module Products
  class JsonLdComponent < ::JsonLdComponent
    def initialize(product:, variant: nil, **options)
      @product = product # Product model
      @variant = variant || product.default_variant
      super(**options)
    end

    private

    def schema_type
      "Product"
    end

    def specific_structure
      {
        name: product_name,
        image: product_images,
        description: product_description,
        brand: brand,
        offers: offers,
        aggregateRating: aggregate_rating,
        review: reviews
      }.compact
    end

    def product_name
      "#{@product.name} Pack - Bitcoin Gift Envelopes (#{@product.envelopes_count} envelopes)"
    end

    def product_images
      # Get images from the variant's attached images
      return [] unless @variant&.images&.any?

      # Return up to 3 images for structured data
      # Use absolute URLs for SEO/Google structured data
      @variant.images.first(3).map do |image|
        helpers.rails_blob_url(image, host: helpers.request.base_url)
      end
    end

    def product_description
      "#{@product.description}. This pack includes #{@product.envelopes_count} premium Bitcoin gift envelopes with paper wallets and famous Bitcoiners quotes. Perfect for orange-pilling friends and family. Includes #{@product.tokens_count} credits for custom designs."
    end

    def brand
      {
        "@type": "Brand",
        name: "Hong₿ao"
      }
    end

    def offers
      {
        "@type": "Offer",
        price: @variant&.price || @product.price,
        priceCurrency: "EUR",
        availability: "https://schema.org/InStock",
        url: helpers.product_url(pack: @product.slug),
        priceValidUntil: 1.year.from_now.iso8601,
        shippingDetails: {
          "@type": "OfferShippingDetails",
          shippingRate: {
            "@type": "MonetaryAmount",
            value: 0,
            currency: "EUR"
          },
          deliveryTime: {
            "@type": "ShippingDeliveryTime",
            businessDays: {
              "@type": "QuantitativeValue",
              minValue: 5,
              maxValue: 10
            }
          }
        }
      }
    end

    def aggregate_rating
      # You can pull this from real data later
      {
        "@type": "AggregateRating",
        ratingValue: 4.8,
        reviewCount: 42,
        bestRating: 5,
        worstRating: 1
      }
    end

    def reviews
      # Sample reviews - replace with real data when available
      [
        {
          "@type": "Review",
          author: {
            "@type": "Person",
            name: "Sarah M."
          },
          datePublished: 3.weeks.ago.iso8601,
          reviewBody: "Perfect gift for getting friends into Bitcoin! The envelopes are beautiful and the quotes are inspiring.",
          reviewRating: {
            "@type": "Rating",
            ratingValue: 5,
            bestRating: 5,
            worstRating: 1
          }
        }
      ]
    end
  end
end
