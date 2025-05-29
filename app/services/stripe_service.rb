class StripeService
  CACHE_KEY = "stripe_prices"
  CACHE_DURATION = 2.hours

  class << self
    def fetch_products
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_DURATION) do
        Stripe::Product.list(
        active: true,
        expand: [ "data.default_price" ],
        ids: ENV.fetch("STRIPE_PRODUCT_IDS").split(",")
      ).data.map do |product|
        {
          stripe_product_id: product.id,
          stripe_price_id: product.default_price.id,
          name: product.name,
          tokens: product.metadata.tokens.to_i,
          envelopes: product.metadata.envelopes.to_i,
          description: product.description,
          price: product.default_price.unit_amount.to_f / 100,
          slug: product.metadata.slug
        }
        end
      end
    end

    def fetch_prices
        # Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_DURATION) do
        Stripe::Price.list(
          active: true,
          expand: [ "data.product" ],
          product: ENV.fetch("STRIPE_PRODUCT_ID")
        ).data.map do |price|
          {
            stripe_price_id: price.id,
            name: price.product.name,
            tokens: price.transform_quantity.divide_by,
            description: price.product.description,
            price: price.unit_amount.to_f / 100,
            default: price.product.default_price == price.id
          }
        end.sort_by { |price| price[:tokens] }
      # end
    end
  end
end
