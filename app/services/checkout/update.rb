module Checkout
  class Update < ApplicationService
    def call(current_user:)
      @user = current_user
      create_portal_session
    end

    private

    def create_portal_session
      failure "Unable to manage billing: No Stripe customer ID found." unless @user.stripe_customer_id

      success Stripe::BillingPortal::Session.create({
        customer: @user.stripe_customer_id,
        return_url: tokens_url
      })
    end
  end
end
