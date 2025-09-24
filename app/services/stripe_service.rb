class StripeService
  CACHE_DURATION = 2.hours

  class << self
    def fetch_products
      Rails.cache.fetch("stripe_products", expires_in: CACHE_DURATION) do
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
        end.sort_by { |product| product[:price] }
      end
    end
  end
end
