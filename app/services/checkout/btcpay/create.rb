module Checkout
  module Btcpay
    class Create < Checkout::Create
      private

      def provider_specific_call(variant)
        # Initialize the BTCPay API client
        client = Client::BtcpayApi.new
        redirect_ref = SecureRandom.hex(16) # unique redirect reference
        product = variant.product
        color_names = variant.color_option_values.map(&:name).join(", ")

        # Create invoice payload
        invoice_payload = {
          amount: variant.price.to_s,
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
            amount: variant.price,
            variant_id: variant.id,
            product_id: product.id,
            color: color_names,
            description: product.description,
            envelopes: product.envelopes_count,
            tokens: product.tokens_count,
            title: product.name,
            itemDesc: "#{color_names.capitalize} #{product.name} - #{product.description}",
            itemCode: variant.stripe_price_id || variant.sku,
            physical: "true",
            userId: @current_user&.id, # nil if not logged in
            buyerEmail: @current_user&.email || @params[:buyerEmail],
            buyerName: "#{@params[:buyerFirstName]} #{@params[:buyerLastName]}",
            buyerPhone: @params[:buyerPhone],
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
