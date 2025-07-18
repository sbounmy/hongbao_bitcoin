module Checkout
  module Btcpay
    class Create < Checkout::Create
      private

      def provider_specific_call(product)
        # Create order first (Bitcoin payments need tracking)
        Rails.logger.info "Creating order for product: #{product.inspect}"
        client = Client::BtcpayApi.new
        pr_payload = {
          amount: product[:price].to_s,
          currency: "EUR",
          title: "#{product[:color].capitalize} #{product[:name]}",
          description: product[:description],
          formId: ENV["BTCPAY_FORM_ID"],
          expiryDate: 1.hours.from_now.to_i,
          referenceId: "#{SecureRandom.hex(10)}_#{@current_user&.id || 'guest'}",
        }

        payment_request = client.create_payment_request(**pr_payload)

        if payment_request.id
          payment_request.url = "https://#{ENV["BTCPAY_HOST"]}/payment-requests/#{payment_request.id}"
          success(payment_request)
        else
          failure(payment_request.message || "Failed to create BTCPay Payment Request")
        end
      end
    end
  end
end
