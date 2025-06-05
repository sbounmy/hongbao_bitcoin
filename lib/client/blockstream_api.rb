require_relative "base"

module Client
  class BlockstreamApi < Client::Base
    url "https://blockstream.info/api"
    url_dev "https://blockstream.info/testnet/api"

    # Address endpoints - core functionality for Balance model
    get "/address/:address", as: :get_address
    get "/address/:address/txs", as: :get_address_transactions
    get "/address/:address/utxo", as: :get_address_utxos

    # Transaction endpoints - needed for transaction details in balance view
    get "/tx/:txid", as: :get_transaction
    get "/tx/:txid/status", as: :get_transaction_status

    # Block endpoints - needed for confirmations calculation
    get "/blocks/tip/height", as: :get_tip_height

    private

    def api_key_credential_path
      [:blockstream, :api_key]
    end
  end
end