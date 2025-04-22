module Checkout
  class Success < ApplicationService
    def call(session_id, authenticated: false)
      # Handle successful payment
      @checkout_session = Stripe::Checkout::Session.retrieve(session_id)
      Rails.logger.info("checkout_session: #{@checkout_session.inspect}")
      @user = User.find_by(email: @checkout_session.customer_details.email)
      Rails.logger.info("user: #{@user.inspect}")
      if !authenticated
        @user ||= User.create!(email: @checkout_session.customer_details.email, password: SecureRandom.hex(16), stripe_customer_id: @checkout_session.customer)
      end
      success @user
    end
  end
end
