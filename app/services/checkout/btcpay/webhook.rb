module Checkout
  module Btcpay
    class Webhook < ApplicationService
      def call(request)
        @request = request
        @payload = request.body.read
        @sig_header = request.env["HTTP_BTCPAY_SIG"]

        return failure("BTCPaySig header is missing") unless @sig_header
        return failure("Webhook signature is invalid") unless signature_valid?

        handle_event
      end

      private

      def handle_event
        payment_request_id = event_data.dig("metadata", "paymentRequestId") || event_data["paymentRequestId"]
        order = Order.find_by(external_id: payment_request_id)

        # Idempotency check: Do not process an order that is already finalized.
        return success("Order ##{order.id} already processed") if order && order&.completed? || order&.failed?

        case event_data["type"]
        when "InvoiceReceivedPayment"
          metadata = event_data["metadata"]

          client = Client::BtcpayApi.new
          payment_request = client.get_payment_request(payment_request_id)
          user_id = payment_request.referenceId.split("_").last

          color = payment_request.title.split(" ").first
          tokens, envelopes = parse_description_details(payment_request.description)

          user = find_or_create_user(user_id, email: metadata["buyerEmail"])

          order = user.orders.create!(
            total_amount: payment_request.amount,
            currency: payment_request.currency,
            payment_provider: "btcpay",
            external_id: payment_request_id,
            shipping_name: metadata["buyerName"],
            shipping_address_line1: metadata["buyerAddress1"],
            shipping_address_line2: metadata["buyerAddress2"],
            shipping_city: metadata["buyerCity"],
            shipping_state: metadata["buyerState"],
            shipping_postal_code: metadata["buyerZip"],
            shipping_country: metadata["buyerCountry"]
          )

          Rails.logger.info "Creating line item for order ##{order.id} with tokens: #{tokens}, envelopes: #{envelopes}, color: #{color}"

          order.line_items.create!(
            quantity: 1,
            price: payment_request.amount,
            metadata: {
              name: payment_request.title,
              tokens: tokens.to_i,
              envelopes: envelopes.to_i,
              description: payment_request.description,
              color: color
            }
          )

          Rails.logger.info "Order ##{order.id} created with line item for order: #{order.inspect}"

        when "InvoiceProcessing"
          return failure("Order not found for ID: #{payment_request_id}") unless order

          order.process! if order.may_process?
        when "PaymentRequestStatusChanged"
          return failure("Order not found for ID: #{payment_request_id}") unless order

          case event_data["status"]
          when "Completed"
            # Payment is complete.
            order.complete! if order.may_complete?

            # Give user tokens
            product = order.line_items.first.metadata
            order.user.tokens.create!(
              quantity: product["tokens"],
              description: product["description"],
              external_id: order.external_id,
              metadata: {
                envelopes: product["envelopes"],
                color: product["color"]
              }
            )
          when "Expired"
            order.fail! if order.may_fail?
          end
        end

        success(order)
      end

      def parse_description_details(description)
        description.split(" + ").map { |part| part.split(" ").first }
      end

      def find_or_create_user(reference_id, email: nil)
        user = User.find(reference_id)
        return user if user

        # If the user is not found, create a new one using the provided email.
        password = SecureRandom.hex(16)
        User.create!(
          email: email,
          password: password,
        )
      end

      def save_shipping_address(order, metadata)
        return if metadata.blank? || order.shipping_name.present?

        order.update(
          shipping_name: metadata["buyerName"],
          shipping_address_line1: metadata["buyerAddress1"],
          shipping_address_line2: metadata["buyerAddress2"],
          shipping_city: metadata["buyerCity"],
          shipping_state: metadata["buyerState"],
          shipping_postal_code: metadata["buyerZip"],
          shipping_country: metadata["buyerCountry"]
        )
      end

      def event_data
        @event_data ||= JSON.parse(@payload)
      end

      def signature_valid?
        secret = Rails.application.credentials.dig(:btcpay, :webhook_secret)
        return false unless secret
        signature = "sha256=" + OpenSSL::HMAC.hexdigest("sha256", secret, @payload)
        Rack::Utils.secure_compare(signature, @sig_header)
      end
    end
  end
end
