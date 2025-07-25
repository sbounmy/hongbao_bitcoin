module Checkout
  module Stripe
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
          cs = ::Stripe::Checkout::Session.retrieve({ id: session.id, expand: [ "line_items", "line_items.data.price.product" ] })
          # Find or create user from checkout session email
          user = find_or_create_user(session.customer_details.email)
          return failure("Unable to find or create user") unless user

          # payment_intent is nil for order full coupon
          if session.payment_intent.present? && Token.find_by(external_id: session.payment_intent) # to avoid duplicate tokens when stripe retries for no reason
            Rails.logger.info("#{session.payment_intent} Token already exists for session #{session.id}")
            return success(user)
          end

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

            order =  user.orders.create!(
              total_amount: cs.amount_total/100.0, # Convert cents to dollars
              currency: cs.currency,
              payment_provider: "stripe",
              external_id: session.payment_intent,
            )

            order.complete! if order.may_complete?

            order.line_items.create!(
              quantity: 1,
              price: cs.amount_total/100.0, # Convert cents to dollars
              stripe_price_id: cs.line_items.data.first.price.id,
              metadata: {
                name: cs.line_items.data.first.price.product.name,
                tokens: cs.line_items.data.first.price.product.metadata.tokens,
                envelopes: cs.line_items.data.first.price.product.metadata.envelopes,
                description: cs.line_items.data.first.price.product.description,
                color: cs.line_items.data.first.price.product.metadata.color
              }
            )



          success user
        else
          Rails.logger.error("Unknown event type: #{event.type}")
          success
        end
      end

      def find_or_create_user(email)
        return nil if email.blank?

        user = User.find_by(email: email)
        return user if user

        # Create new user for guest checkout
        password = SecureRandom.hex(16)
        User.create!(
          email: email,
          password: password
        )
      end

      def event
        @event ||= ::Stripe::Webhook.construct_event(@payload, @sig_header, endpoint_secret)
      end
      def endpoint_secret
        Rails.application.credentials.dig(:stripe, :signing_secret)
      end
    end
  end
end
