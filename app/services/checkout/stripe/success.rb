module Checkout
  module Stripe
    class Success < ApplicationService
      def call(session_id, authenticated: false)
        # Handle successful payment
        @checkout_session = Stripe::Checkout::Session.retrieve(session_id)
        Rails.logger.info("checkout_session: #{@checkout_session.inspect}")
        if @user = User.find_by(email: @checkout_session.customer_details.email)
          @user.update!(stripe_customer_id: @checkout_session.customer) if @user.stripe_customer_id.nil?
        end
        Rails.logger.info("user: #{@user.inspect}")
        success @user
      end
    end
  end
end
