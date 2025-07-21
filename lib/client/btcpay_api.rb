require_relative "base"

module Client
  class BtcpayApi < Client::Base
    url "https://#{ENV["BTCPAY_HOST"]}"

    auth_prefix "token"

    store_id = Rails.application.credentials.dig(:btcpay, :store_id)

    # Create a new invoice
    post "/api/v1/stores/#{store_id}/invoices", as: :create_invoice

    private

    def api_key_credential_path
      [ :btcpay, :api_key ]
    end
  end
end
