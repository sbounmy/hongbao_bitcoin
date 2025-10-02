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
          user = User.find_by(email: session.customer_details.email)

          if user.nil?
            # Create new user for guest checkout
            password = SecureRandom.hex(16)
            user = User.create!(
              email: session.customer_details.email,
              password: password
            )

            # Send welcome email for new guest account
            AuthMailer.account_created(user).deliver_later
          end

          return failure("Unable to find or create user") unless user

          # Update stripe customer ID if not already set
          if session.customer.present? && user.stripe_customer_id.blank?
            user.update!(stripe_customer_id: session.customer)
          end

          # payment_intent is nil for order full coupon
          if session.payment_intent.present? && Token.find_by(external_id: session.payment_intent) # to avoid duplicate tokens when stripe retries for no reason
            Rails.logger.info("#{session.payment_intent} Token already exists for session #{session.id}")
            return success(user)
          end

          Rails.logger.info("Creating #{cs.line_items.data.first.price.product.metadata.tokens} token for session #{session.id}")
          user.tokens.create!(
              quantity: cs.line_items.data.first.price.product.metadata.tokens,
              description: "Tokens purchased from Stripe #{session.payment_intent}",
              external_id: session.payment_intent || session.id,
              metadata: {
                stripe_checkout_session_id: session.id,
                stripe_checkout_session_url: session.url,
                stripe_checkout_session_payment_status: session.payment_status,
                stripe_checkout_session_payment_intent: session.payment_intent
              }
            )

            Rails.logger.info("-----Session #{session.id} #{session.customer_details.inspect} / #{cs.inspect}")
            shipping_details = cs.collected_information.shipping_details
            order =  user.orders.create!(
              total_amount: cs.amount_total/100.0, # Convert cents to dollars
              currency: cs.currency,
              payment_provider: "stripe",
              external_id: session.payment_intent || session.id,
              phone_number: session.customer_details.phone,
              shipping_name: shipping_details.name,
              shipping_address_line1: shipping_details.address.line1,
              shipping_address_line2: shipping_details.address.line2,
              shipping_city: shipping_details.address.city,
              shipping_state: shipping_details.address.state,
              shipping_postal_code: shipping_details.address.postal_code,
              shipping_country: shipping_details.address.country
            )

            order.complete! if order.may_complete?

            order.line_items.create!(
              quantity: 1,
              price: cs.amount_total/100.0, # Convert cents to dollars
              stripe_price_id: cs.line_items.data.first.price.id,
              metadata: {
                name: cs.line_items.data.first.price.product.name,
                tokens: cs.line_items.data.first.price.product.metadata["tokens"],
                envelopes: cs.line_items.data.first.price.product.metadata["envelopes"],
                description: cs.line_items.data.first.price.product.description,
                color: cs.line_items.data.first.price.product.metadata["color"]
              }
            )



          success user
        else
          Rails.logger.error("Unknown event type: #{event.type}")
          success
        end
        # rescue => e # uncomment this in dev so we can see the error
        #   Rails.logger.error("Error creating order for session #{session.inspect}: #{e.message}")
        #   failure e.message
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
