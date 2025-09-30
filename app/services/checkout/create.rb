module Checkout
  class Create < Base
    def call(params:, current_user:, currency: "EUR")
      @params = params
      @current_user = current_user
      @currency = currency

      # 1. Find the variant
      variant_id = @params[:variant_id]
      return failure("Variant ID is missing.") unless variant_id

      @variant = Variant.find_by(id: variant_id)
      return failure("Variant not found for ID: #{variant_id}") unless @variant

      # 2. Call provider-specific implementation
      provider_specific_call(@variant)
    end
  end
end
