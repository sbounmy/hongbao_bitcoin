module Checkout
  module Stripe
    class Update < ApplicationService
      def call(current_user:)
        @user = current_user
        success portal_session
      end
      private
      def portal_session
        failure "Unable to manage billing: No Stripe customer ID found." unless @user.stripe_customer_id
         Stripe::BillingPortal::Session.create({
          customer: @user.stripe_customer_id,
          return_url: tokens_url
        })
      end
    end
  end
end
