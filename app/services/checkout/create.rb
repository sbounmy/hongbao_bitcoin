module Checkout
  class Create < ApplicationService
    def call(params, current_user: nil)
      @params = params
      @current_user = current_user
      session = Stripe::Checkout::Session.create(checkout_params)
      success session
    end

    private

    def checkout_params
      p = {
        payment_method_types: [ "card" ],
        shipping_address_collection: {

          allowed_countries: [
            "AC", "AD", "AE", "AF", "AG", "AI", "AL", "AM", "AO", "AQ", "AR", "AT", "AU", "AW", "AX",
            "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BL", "BM", "BN", "BO", "BQ",
            "BR", "BS", "BT", "BV", "BW", "BY", "BZ", "CA", "CD", "CF", "CG", "CH", "CI", "CK", "CL",
            "CM", "CN", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC",
            "EE", "EG", "EH", "ER", "ES", "ET", "FI", "FJ", "FK", "FO", "FR", "GA", "GB", "GD", "GE",
            "GF", "GG", "GH", "GI", "GL", "GM", "GN", "GP", "GQ", "GR", "GS", "GT", "GU", "GW", "GY",
            "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IM", "IN", "IO", "IQ", "IS", "IT", "JE",
            "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KY", "KZ", "LA", "LB",
            "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "LY", "MA", "MC", "MD", "ME", "MF", "MG",
            "MK", "ML", "MM", "MN", "MO", "MQ", "MR", "MS", "MT", "MU", "MV", "MW", "MX", "MY", "MZ",
            "NA", "NC", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NU", "NZ", "OM", "PA", "PE", "PF",
            "PG", "PH", "PK", "PL", "PM", "PN", "PR", "PS", "PT", "PY", "QA", "RE", "RO", "RS", "RU",
            "RW", "SA", "SB", "SC", "SD", "SE", "SG", "SH", "SI", "SJ", "SK", "SL", "SM", "SN", "SO",
            "SR", "SS", "ST", "SV", "SX", "SZ", "TA", "TC", "TD", "TF", "TG", "TH", "TJ", "TK", "TL",
            "TM", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VA", "VC",
            "VE", "VG", "VN", "VU", "WF", "WS", "XK", "YE", "YT", "ZA", "ZM", "ZW", "ZZ"
          ] # allow countries
        },
        line_items: [ {
          price: @params[:price_id],
          quantity: 1
        } ],
        mode: "payment",
        success_url: CGI.unescape(success_checkout_index_url(session_id: "{CHECKOUT_SESSION_ID}")), # so {CHECKOUT_SESSION_ID} is not escaped
        cancel_url: cancel_checkout_index_url
      }
      if @current_user
        if @current_user.stripe_customer_id
          p[:customer] = @current_user.stripe_customer_id
        else
          p[:customer_email] = @current_user.email
          p[:customer_creation] = "always"
        end
        p[:allow_promotion_codes] = @current_user.admin
        if ENV["STRIPE_CONTEXT_ID"].present?
          p[:client_reference_id] = "#{ENV['STRIPE_CONTEXT_ID']}#user_#{@current_user.id}"
        end
      end
      p
    end
  end
end
