module Checkout
  class Webhook < ApplicationService
    def call(request)
      @payload = request.body.read
      @sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      handle_event
    end

    private

    def handle_event
      case event.type
      when "checkout.session.completed"
        session = event.data.object
        client_reference_id = session.client_reference_id
        Rails.logger.info("client_reference_id: #{client_reference_id}")

        # In a sharded test environment, we only process webhooks designated for this specific shard.
        if Rails.env.test?
          context_id = ENV["STRIPE_CONTEXT_ID"]
          return success if context_id.present? && !client_reference_id&.start_with?(context_id)
        end

        Rails.logger.info("event: #{event.id} session##{session.id}: #{event.inspect}")

        cs = Stripe::Checkout::Session.retrieve({ id: session.id, expand: [ "line_items", "line_items.data.price.product" ] })
        user = User.find_by(email: session.customer_details.email)

        # payment_intent is nil for order full coupon
        if session.payment_intent.present? && Token.find_by(external_id: session.payment_intent) # to avoid duplicate tokens when stripe retries for no reason
          Rails.logger.info("#{session.payment_intent} Token already exists for session #{session.id}")
          success(user)
        elsif user.save!
          Rails.logger.info("Creating token for session #{session.id}")
          user.tokens.create!(
            quantity: cs.line_items.data.first.price.product.metadata.tokens,
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
        Rails.logger.error("Unknown event type: #{event.type}")
        success
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
