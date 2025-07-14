module Checkout
  class Create < Base
    def call(params:, current_user:, currency: "EUR")
      @params = params
      @current_user = current_user
      @currency = currency
      # 1. Find the product
      price_id = @params[:price_id]
      return failure("Price ID is missing.") unless price_id

      product = StripeService.fetch_products.find { |p| p[:stripe_price_id] == price_id }
      return failure("Product not found for price ID: #{price_id}") unless product

      # 2. Create the Order and LineItem
      order = create_order_and_line_item(product)

      # This calls the `provider_specific_call` method in the child class
      provider_specific_call(order, product)
    end

    private

    def create_order_and_line_item(product)
      order = Order.create!(
        user: @current_user,
        total_amount: product[:price],
        currency: @currency,
        payment_provider: @params[:provider],
        external_id: "external_id_#{SecureRandom.hex(10)}"
      )

      order.line_items.create!(
        quantity: 1,
        price: product[:price],
        stripe_price_id: product[:stripe_price_id],
        metadata: {
          name: product[:name],
          tokens: product[:tokens],
          envelopes: product[:envelopes],
          description: product[:description],
          color: @params[:color]
        }
      )
      order
    end
  end
end
