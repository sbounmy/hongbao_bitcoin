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
      product[:color] = @params[:color]
      
      return failure("Product not found for price ID: #{price_id}") unless product

      # 2. Call provider-specific implementation
      provider_specific_call(product)
    end
  end
end
