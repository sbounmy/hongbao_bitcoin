module Checkout
  module Btcpay
    class Create < Checkout::Create
      private

      def provider_specific_call(product)
        # Initialize the BTCPay API client
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
            description: product[:description],
            envelopes: product[:envelopes],
            tokens: product[:tokens],
            title: product[:name],
            itemDesc: "#{product[:color].capitalize} #{product[:name]} - #{product[:description]}",
            itemCode: product[:stripe_price_id],
            physical: "true",
            userId: @current_user&.id || "guest",
            buyerEmail: @current_user&.email || @params[:email],
            buyerName: @params[:shipping_name],
            buyerAddress1: @params[:shipping_address_line1],
            buyerAddress2: @params[:shipping_address_line2],
            buyerCity: @params[:shipping_city],
            buyerState: @params[:shipping_state],
            buyerZip: @params[:shipping_postal_code],
            buyerCountry: @params[:shipping_country]
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
