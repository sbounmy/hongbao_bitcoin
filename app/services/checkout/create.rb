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

      # Handle admin-only product
      if product.nil? && @current_user&.admin? && price_id == StripeService::ADMIN_PRICE_ID
        product = StripeService.fetch_admin_product
      end

      return failure("Product not found for price ID: #{price_id}") unless product

      product[:color] = @params[:color]

      # 2. Call provider-specific implementation
      provider_specific_call(product)
    end
  end
end
