require_relative "base"

module Client
  class BtcpayApi < Client::Base
    url ENV["BTCPAY_SERVER"]

    auth_prefix "token"

    store_id = Rails.application.credentials.dig(:btcpay, :store_id)
    # Create a payment request to hold customer and shipping info.
    post "/api/v1/stores/#{store_id}/payment-requests", as: :create_payment_request
    get "/api/v1/stores/#{store_id}/payment-requests/:payment_request_id", as: :get_payment_request

    private

    def api_key_credential_path
      [ :btcpay, :api_key ]
    end
  end
end
