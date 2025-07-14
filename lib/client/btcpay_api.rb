require_relative "base"

module Client
  class BtcpayApi < Client::Base
    url Rails.application.credentials.dig(:btcpay, :server_url)

    # Create a payment request to hold customer and shipping info.
    post "/api/v1/stores/:store_id/payment-requests", as: :create_payment_request

    private

    def api_key_credential_path
      [ :btcpay, :api_key ]
    end

    # Add an authorization header required by the Greenfield API
    def build_request(http_method, uri, **params)
      request = super(http_method, uri, **params)
      request["Authorization"] = "token #{@api_key}"
      request
    end

    # Override build_url to add the store_id automatically
    def build_url(path, args, params)
      # The store_id is always needed, so we can inject it automatically.
      path_with_store = path.gsub(":store_id", Rails.application.credentials.dig(:btcpay, :store_id))
      super(path_with_store, args, params)
    end
  end
end
