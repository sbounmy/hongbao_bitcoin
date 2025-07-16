module Checkout
  module Btcpay
    class Create < Checkout::Create
      private

      def provider_specific_call(product)
        # Create order first (Bitcoin payments need tracking)
        order = create_order_and_line_item(product)
        client = Client::BtcpayApi.new
        pr_payload = {
          amount: order.total_amount.to_s,
          currency: order.currency,
          title: order.line_items.first.metadata["name"],
          description: order.line_items.first.metadata["description"],
          formId: ENV["BTCPAY_FORM_ID"],
          expiryDate: 1.hours.from_now.to_i,
          referenceId: "#{SecureRandom.hex(10)}_#{order.id}"
        }
        payment_request = client.create_payment_request(**pr_payload)

        if payment_request.id
          order.update!(external_id: payment_request.id)
          payment_request.url = "#{ENV["BTCPAY_SERVER"]}/payment-requests/#{payment_request.id}"
          success(payment_request)
        else
          order.fail! if order.may_fail?
          failure(payment_request.message || "Failed to create BTCPay Payment Request")
        end
      end
    end
  end
end
