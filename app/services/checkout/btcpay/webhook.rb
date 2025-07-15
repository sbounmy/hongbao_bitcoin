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
        # The referenceId is in the metadata, which we passed when creating the Payment Request.
        payment_request_id = event_data.dig("metadata", "paymentRequestId") || event_data["paymentRequestId"]
        order = Order.find_by(external_id: payment_request_id.split("_").last)

        return failure("Order not found for ID: #{payment_request_id}") unless order

        # Idempotency check: Do not process an order that is already finalized.
        return success("Order ##{order.id} already processed") if order.completed? || order.failed?

        case event_data["type"]
        when "InvoiceCreated"
          # the user has submitted the form. Save their infos but keep the order pending.
          save_shipping_address(order, event_data.dig("metadata"))
          # if the user is not logged in, we can create a user based on the email provided.
          find_or_create_user(order, event_data.dig("metadata", "buyerEmail"))
        when "InvoiceProcessing"
          order.process! if order.may_process?
        when "PaymentRequestStatusChanged"
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

      def find_or_create_user(order, email)
        return if order.user.present? || email.blank?

        user = User.find_or_create_by(email: email.downcase) do |u|
          u.password = SecureRandom.hex(16)
        end
        order.update!(user: user)
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
