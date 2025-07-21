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
        invoice_id = event_data["invoiceId"] || event_data["id"]
        order = Order.find_by(external_id: invoice_id)

        # Idempotency check: Do not process an order that is already finalized.
        return success("Order ##{order.id} already processed") if order && order&.completed? || order&.failed?

        case event_data["type"]
        when "InvoiceReceivedPayment"
          metadata = event_data["metadata"]
          user_id = metadata["userId"]
          user = find_or_create_user(user_id, email: metadata["buyerEmail"])

          order = user.orders.create!(
            total_amount: metadata["amount"],
            currency: metadata["currency"],
            payment_provider: "btcpay",
            external_id: invoice_id,
            redirect_ref: metadata["redirectRef"],
            shipping_name: metadata["buyerName"],
            shipping_address_line1: metadata["buyerAddress1"],
            shipping_address_line2: metadata["buyerAddress2"],
            shipping_city: metadata["buyerCity"],
            shipping_state: metadata["buyerState"],
            shipping_postal_code: metadata["buyerZip"],
            shipping_country: metadata["buyerCountry"]
          )

          order.line_items.create!(
            quantity: 1,
            price: metadata["amount"],
            metadata: {
              name: metadata["title"],
              tokens: metadata["tokens"].to_i,
              envelopes: metadata["envelopes"].to_i,
              description: metadata["description"],
              color: metadata["color"]
            }
          )

          Rails.logger.info "Order ##{order.id} created with line item for order: #{order.inspect}"

        when "InvoiceProcessing"
          return failure("Order not found for ID: #{invoice_id}") unless order

          order.process! if order.may_process?
        when "InvoiceExpired"
          return failure("Order not found for ID: #{invoice_id}") unless order

          order.fail! if order.may_fail?
        when "InvoiceSettled"
          return failure("Order not found for ID: #{invoice_id}") unless order

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
        end

        success(order)
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
