module Checkout
  module Stripe
    class Success < ApplicationService
      def call(session_id)
        return failure("Session ID is required") if session_id.blank?

        checkout_session = ::Stripe::Checkout::Session.retrieve(session_id)
        Rails.logger.info("checkout_session: #{checkout_session.inspect}")

        success(checkout_session)
      rescue ::Stripe::InvalidRequestError => e
        Rails.logger.error("Invalid Stripe session: #{e.message}")
        failure("Invalid session")
      end
    end
  end
end
