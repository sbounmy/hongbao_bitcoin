module Checkout
  class Create < ApplicationService
    def call(params, current_user: nil)
      @params = params
      @current_user = current_user
      session = Stripe::Checkout::Session.create(checkout_params)
      success session
    end

    private

    def checkout_params
      p = {
        payment_method_types: [ "card" ],
        line_items: [ {
          price: @params[:price_id],
          quantity: 1
        } ],
        mode: "payment",
        success_url: CGI.unescape(success_checkout_index_url(session_id: "{CHECKOUT_SESSION_ID}")), # so {CHECKOUT_SESSION_ID} is not escaped
        cancel_url: cancel_checkout_index_url
      }
      if @current_user
        if @current_user.stripe_customer_id
          p[:customer] = @current_user.stripe_customer_id
        else
          p[:customer_email] = @current_user.email
        end
      end
      p[:allow_promotion_codes] = @current_user&.admin
      p
    end
  end
end
