module Tokens
  class Paid < ApplicationService
    def call(payload:, sig_header:)
      @payload = payload
      @sig_header = sig_header

      handle_event
    end

    private

    def handle_event
      case event.type
      when "payment_intent.succeeded"
        session = event.data.object
        # Handle the checkout session here
        # You can access session.customer, session.payment_status, etc.
      end
    end

    def event
      @event ||= Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    end

    def endpoint_secret
      Rails.application.credentials.dig(:stripe, :signing_secret)
    end
  end
end
