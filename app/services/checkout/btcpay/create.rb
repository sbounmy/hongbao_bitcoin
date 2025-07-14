module Checkout
  module Btcpay
    class Create < Checkout::Create
      private

      def provider_specific_call(order, product)
        client = Client::BtcpayApi.new
        pr_payload = {
          amount: order.total_amount.to_s,
          currency: order.currency,
          title: order.line_items.first.metadata["name"],
          description: order.line_items.first.metadata["description"],
          formId: ENV["BTCPAY_FORM_ID"],
          referenceId: order.id
        }

        payment_request = client.create_payment_request(**pr_payload)

        if payment_request.id
          order.update!(external_id: payment_request.id)
          payment_request.url = "#{Rails.application.credentials.dig(:btcpay, :server_url)}/payment-requests/#{payment_request.id}"
          success(payment_request)
        else
          order.fail! if order.may_fail?
          failure(payment_request.message || "Failed to create BTCPay Payment Request")
        end
      end
    end
  end
end
