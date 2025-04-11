class StripeService
  CACHE_KEY = "stripe_prices"
  CACHE_DURATION = 2.hours

  class << self
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
            price: price.unit_amount.to_f / 100,
            default: price.product.metadata["default"] == "true"
          }
        end.sort_by { |price| price[:tokens] }
      # end
    end
  end
end
