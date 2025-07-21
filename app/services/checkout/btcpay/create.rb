module Checkout
  module Btcpay
    class Create < Checkout::Create
      private

      def provider_specific_call(product)
        # Create order first (Bitcoin payments need tracking)
        Rails.logger.info "Creating order for product: #{@params[:payment_method]}"
        client = Client::BtcpayApi.new

        # Create invoice payload
        invoice_payload = {
          amount: product[:price].to_s,
          currency: "EUR",
          checkout: {
            speedPolicy: "MediumSpeed",
            paymentMethods: [ @params[:payment_method] || "BTC" ],
            defaultPaymentMethod: @params[:payment_method] || "BTC",
            redirectURL: success_checkout_index_url,
            redirectAutomatically: true
          },
          metadata: {
            color: product[:color],
            itemDesc: "#{product[:color].capitalize} #{product[:name]} - #{product[:description]}",
            itemCode: product[:stripe_price_id],
            physical: "true",
            userId: @current_user&.id || "guest"
          }
        }

        invoice = client.create_invoice(**invoice_payload)

        if invoice.id
          invoice.url = invoice.checkoutLink # to match the expected format
          success(invoice)
        else
          failure(invoice.message || "Failed to create BTCPay Invoice")
        end
      end
    end
  end
end
