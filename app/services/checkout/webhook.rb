module Checkout
  class Webhook < ApplicationService
    def call(payload:, sig_header:)
      @payload = payload
      @sig_header = sig_header

      handle_event
    end

    private

    def handle_event
      case event.type
      when "checkout.session.completed"
        Rails.logger.info("event: #{event.inspect}")
        session = event.data.object
        # Handle the checkout session here
        # You can access session.customer, session.payment_status, etc.

        cs = Stripe::Checkout::Session.retrieve({ id: session.id, expand: [ "line_items" ] })
        user = User.find_by(email: session.customer_details.email)
        success(user) if Token.find_by(external_id: session.payment_intent) # to avoid duplicate tokens when stripe retries for no reason

        if user.save!
          user.tokens.create!(
            quantity: cs.line_items&.data&.first&.price&.transform_quantity&.divide_by,
            description: "Tokens purchased from Stripe #{session.payment_intent}",
            external_id: session.payment_intent,
            metadata: {
              stripe_checkout_session_id: session.id,
              stripe_checkout_session_url: session.url,
              stripe_checkout_session_payment_status: session.payment_status,
              stripe_checkout_session_payment_intent: session.payment_intent
            }
          )
          success user
        else
          failure user.errors.full_messages.join(", ")
        end
      else
        failure "Unknown event type: #{event.type}"
      end
    end

    def event
      @event ||= Stripe::Webhook.construct_event(@payload, @sig_header, endpoint_secret)
    end

    def endpoint_secret
      Rails.application.credentials.dig(:stripe, :signing_secret)
    end
  end
end
