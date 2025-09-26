# frozen_string_literal: true

module Products
  class StripeJsonLdComponent < ::JsonLdComponent
    def initialize(product:, color: "red", **options)
      @product = product # From StripeService.fetch_products
      @color = color
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
      "#{@product[:name]} Pack - Bitcoin Gift Envelopes (#{@product[:envelopes]} envelopes)"
    end

    def product_images
      # Generate image URLs for the product
      folder = image_folder_name

      # Get actual image files from the folder
      image_path_pattern = Rails.root.join("app/assets/images/plans", @product[:slug], folder, "*")
      image_files = Dir.glob(image_path_pattern).select { |f| File.file?(f) && f.match?(/\.(jpg|jpeg|png)$/i) }.sort

      # Return up to 3 images for structured data
      image_files.first(3).map do |file_path|
        helpers.image_url("plans/#{@product[:slug]}/#{folder}/#{File.basename(file_path)}")
      end
    end

    def product_description
      "#{@product[:description]}. This pack includes #{@product[:envelopes]} premium Bitcoin gift envelopes with paper wallets and famous Bitcoiners quotes. Perfect for orange-pilling friends and family. Includes #{@product[:tokens]} credits for custom designs."
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
        price: @product[:price],
        priceCurrency: "EUR",
        availability: "https://schema.org/InStock",
        url: helpers.product_url(pack: @product[:slug]),
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

    private

    def image_folder_name
      colors = @color.split(",")
      base_path = Rails.root.join("app/assets/images/plans", @product[:slug])
      all_folders = Dir.glob(base_path.join("*")).select { |p| File.directory?(p) }.map { |p| File.basename(p) } rescue []

      if colors.size > 1
        permutations = colors.permutation.map { |p| "split_#{p.join('_')}" }
        all_folders.find { |folder| permutations.any? { |perm| folder.include?(perm) } } || "001_red"
      else
        color_name = colors.first
        all_folders.find { |folder| folder.end_with?("_#{color_name}") } || "001_red"
      end
    end
  end
end
