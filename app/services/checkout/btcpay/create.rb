module Checkout
  module Btcpay
    class Create < Checkout::Create
      private

      def provider_specific_call(product)
        # Initialize the BTCPay API client
        client = Client::BtcpayApi.new
        redirect_ref = SecureRandom.hex(16) # unique redirect reference
        # Create invoice payload
        invoice_payload = {
          amount: product[:price].to_s,
          currency: "EUR",
          checkout: {
            speedPolicy: "MediumSpeed",
            defaultPaymentMethod: @params[:payment_method] || "BTC",
            redirectURL: success_checkout_index_url(provider: "btcpay", session_id: redirect_ref),
            redirectAutomatically: true
          },
          metadata: {
            redirectRef: redirect_ref,
            currency: "EUR",
            amount: product[:price],
            color: product[:color],
            description: product[:description],
            envelopes: product[:envelopes],
            tokens: product[:tokens],
            title: product[:name],
            itemDesc: "#{@params[:color].capitalize} #{product[:name]} - #{product[:description]}",
            itemCode: product[:stripe_price_id],
            physical: "true",
            userId: @current_user&.id || "guest",
            buyerEmail: @current_user&.email || @params[:buyerEmail],
            buyerName: @params[:buyerName],
            buyerAddress1: @params[:buyerAddress1],
            buyerAddress2: @params[:buyerAddress2],
            buyerCity: @params[:buyerCity],
            buyerState: @params[:buyerState],
            buyerZip: @params[:buyerZip],
            buyerCountry: @params[:buyerCountry]
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
