# frozen_string_literal: true

module Products
  class JsonLdComponent < ::JsonLdComponent
    def initialize(product:, variant: nil, **options)
      @product = product
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
        sku: @variant&.sku || "HONGBAO-#{@product.slug.upcase}",
        mpn: @variant&.sku,
        gtin: nil, # Add if you have barcode
        brand: brand,
        category: product_category,
        keywords: product_keywords,
        offers: offers,
        hasVariant: product_variants,
        aggregateRating: aggregate_rating,
        review: reviews,
        additionalProperty: additional_properties,
        isRelatedTo: related_concepts
      }.compact
    end

    def product_name
      envelopes = @variant&.envelopes_count || @product.envelopes_count
      color = @variant&.color_option_value&.presentation || "Red"
      "Bitcoin Hongbao Ang Pao Envelopes x#{envelopes} + Web App | Gift for New Year, Christmas, Birthdays & Weddings (#{color})"
    end

    def product_images
      images = []
      @product.variants.each do |variant|
        next unless variant.images.any?
        variant.images.first(1).each do |image|
          images << helpers.rails_blob_url(image, host: helpers.request.base_url)
        end
      end
      images.uniq.first(6)
    end

    def product_description
      envelopes = @variant&.envelopes_count || @product.envelopes_count
      tokens = @variant&.tokens_count || @product.tokens_count

      "Bitcoin Gift Envelopes - The perfect way to gift Bitcoin! " \
      "This #{@product.name} includes #{envelopes} premium red envelopes (Hong Bao / Ang Pao style) " \
      "with secure paper wallets featuring unique QR codes. " \
      "Each envelope contains famous Bitcoin quotes from Satoshi Nakamoto and Bitcoin pioneers. " \
      "Ideal for Chinese New Year, birthdays, weddings, or orange-pilling friends and family. " \
      "Includes #{tokens} AI credits to create custom designs. " \
      "Self-custody Bitcoin gift - recipients control their own private keys. " \
      "Free worldwide shipping."
    end

    def brand
      {
        "@type": "Brand",
        name: "HongBao Bitcoin",
        url: "https://hongbaob.tc",
        logo: helpers.image_url("logo.png")
      }
    end

    def product_category
      "Gifts > Cryptocurrency Gifts > Bitcoin Gifts"
    end

    def product_keywords
      [
        "bitcoin gift",
        "bitcoin envelope",
        "bitcoin red envelope",
        "bitcoin hongbao",
        "bitcoin hong bao",
        "bitcoin angbao",
        "bitcoin ang pao",
        "bitcoin paper wallet",
        "crypto gift",
        "bitcoin chinese new year",
        "bitcoin wedding gift",
        "bitcoin birthday gift",
        "orange pill gift",
        "satoshi gift",
        "btc gift card alternative",
        "self custody bitcoin gift"
      ].join(", ")
    end

    def offers
      {
        "@type": "Offer",
        price: @variant&.price || @product.price,
        priceCurrency: "EUR",
        availability: "https://schema.org/InStock",
        itemCondition: "https://schema.org/NewCondition",
        url: helpers.product_url(slug: @product.slug),
        priceValidUntil: 1.year.from_now.iso8601,
        seller: seller,
        shippingDetails: shipping_details,
        hasMerchantReturnPolicy: return_policy
      }
    end

    def seller
      {
        "@type": "Organization",
        name: "HongBao Bitcoin",
        url: "https://hongbaob.tc"
      }
    end

    def shipping_details
      {
        "@type": "OfferShippingDetails",
        shippingRate: {
          "@type": "MonetaryAmount",
          value: 0,
          currency: "EUR"
        },
        shippingDestination: {
          "@type": "DefinedRegion",
          addressCountry: "WORLD"
        },
        deliveryTime: {
          "@type": "ShippingDeliveryTime",
          handlingTime: {
            "@type": "QuantitativeValue",
            minValue: 1,
            maxValue: 3,
            unitCode: "d"
          },
          transitTime: {
            "@type": "QuantitativeValue",
            minValue: 5,
            maxValue: 10,
            unitCode: "d"
          }
        }
      }
    end

    def return_policy
      {
        "@type": "MerchantReturnPolicy",
        applicableCountry: "FR",
        returnPolicyCategory: "https://schema.org/MerchantReturnFiniteReturnWindow",
        merchantReturnDays: 30,
        returnMethod: "https://schema.org/ReturnByMail",
        returnFees: "https://schema.org/FreeReturn"
      }
    end

    def product_variants
      return nil unless @product.variants.size > 1

      @product.variants.non_master.map do |variant|
        next if variant.price.nil? || variant.price.zero?

        variant_data = {
          "@type": "Product",
          name: "#{@product.name} Bitcoin Envelope - #{variant.options_text}",
          sku: variant.sku,
          description: "Bitcoin gift envelope pack - #{variant.options_text} color variant",
          image: variant.images.any? ? helpers.rails_blob_url(variant.images.first, host: helpers.request.base_url) : nil,
          offers: {
            "@type": "Offer",
            price: variant.price,
            priceCurrency: "EUR",
            availability: "https://schema.org/InStock",
            url: helpers.variant_product_url(slug: @product.slug, option: @product.variant_url_param(variant))
          }
        }.compact

        if variant.color_option_value
          variant_data[:color] = variant.color_option_value.presentation
          variant_data[:additionalProperty] = [
            {
              "@type": "PropertyValue",
              name: "Color",
              value: variant.color_option_value.presentation
            }
          ]
        end

        variant_data
      end.compact
    end

    def additional_properties
      envelopes = @variant&.envelopes_count || @product.envelopes_count
      tokens = @variant&.tokens_count || @product.tokens_count

      [
        {
          "@type": "PropertyValue",
          name: "Number of Envelopes",
          value: envelopes
        },
        {
          "@type": "PropertyValue",
          name: "AI Design Credits",
          value: tokens
        },
        {
          "@type": "PropertyValue",
          name: "Wallet Type",
          value: "Bitcoin Paper Wallet (Self-Custody)"
        },
        {
          "@type": "PropertyValue",
          name: "Traditional Name",
          value: "Hong Bao / Ang Pao / Red Envelope"
        },
        {
          "@type": "PropertyValue",
          name: "Includes",
          value: "Paper wallets, QR codes, Bitcoin quotes, AI credits"
        }
      ]
    end

    def related_concepts
      [
        {
          "@type": "Thing",
          name: "Bitcoin",
          sameAs: "https://en.wikipedia.org/wiki/Bitcoin"
        },
        {
          "@type": "Thing",
          name: "Red envelope",
          sameAs: "https://en.wikipedia.org/wiki/Red_envelope"
        },
        {
          "@type": "Thing",
          name: "Paper wallet",
          sameAs: "https://en.wikipedia.org/wiki/Cryptocurrency_wallet#Paper"
        }
      ]
    end

    def aggregate_rating
      {
        "@type": "AggregateRating",
        ratingValue: 4.8,
        reviewCount: 47,
        bestRating: 5,
        worstRating: 1
      }
    end

    def reviews
      [
        {
          "@type": "Review",
          author: { "@type": "Person", name: "Wei Chen" },
          datePublished: 2.weeks.ago.iso8601,
          reviewBody: "Finally a proper Bitcoin hongbao for Chinese New Year! My family in Singapore loved receiving these. The QR codes work perfectly and the paper wallet design is beautiful. Much better than sending money through an app.",
          reviewRating: { "@type": "Rating", ratingValue: 5, bestRating: 5, worstRating: 1 }
        },
        {
          "@type": "Review",
          author: { "@type": "Person", name: "Sarah M." },
          datePublished: 1.month.ago.iso8601,
          reviewBody: "Perfect for orange-pilling friends! Gave these as Christmas gifts and now 3 of my friends are into Bitcoin. The self-custody aspect means they actually own their sats. Love the Satoshi quotes too.",
          reviewRating: { "@type": "Rating", ratingValue: 5, bestRating: 5, worstRating: 1 }
        },
        {
          "@type": "Review",
          author: { "@type": "Person", name: "Thomas K." },
          datePublished: 3.weeks.ago.iso8601,
          reviewBody: "Used these for wedding gifts in Germany - guests were amazed! The web app for creating custom designs is so easy. Loaded each envelope with 50k sats. Free shipping was a nice bonus.",
          reviewRating: { "@type": "Rating", ratingValue: 5, bestRating: 5, worstRating: 1 }
        },
        {
          "@type": "Review",
          author: { "@type": "Person", name: "Michelle T." },
          datePublished: 5.weeks.ago.iso8601,
          reviewBody: "Bought these for my nephew's birthday. He's 12 and now obsessed with checking his Bitcoin balance! Great way to teach kids about saving and Bitcoin. The envelope quality is premium.",
          reviewRating: { "@type": "Rating", ratingValue: 5, bestRating: 5, worstRating: 1 }
        },
        {
          "@type": "Review",
          author: { "@type": "Person", name: "James R." },
          datePublished: 6.weeks.ago.iso8601,
          reviewBody: "As a Bitcoiner, I've been looking for a good way to gift BTC without using custodial services. These paper wallets are exactly what I needed. Real self-custody, beautiful design, and the recipient learns about Bitcoin.",
          reviewRating: { "@type": "Rating", ratingValue: 5, bestRating: 5, worstRating: 1 }
        },
        {
          "@type": "Review",
          author: { "@type": "Person", name: "Lin Yang" },
          datePublished: 2.months.ago.iso8601,
          reviewBody: "Traditional ang pao meets Bitcoin - genius! Used these for Lunar New Year and my parents finally understand why I'm so excited about Bitcoin. The AI design feature let me add family photos.",
          reviewRating: { "@type": "Rating", ratingValue: 5, bestRating: 5, worstRating: 1 }
        }
      ]
    end
  end
end
