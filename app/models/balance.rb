require 'net/http'
require 'json'

class Balance
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :satoshis, :integer, default: 0
  attribute :confirmations, :integer, default: 0
  attribute :exchange_rate, :float
  attribute :address, :string

  SATOSHIS_PER_BTC = 100_000_000
  COINBASE_URI = URI('https://api.coinbase.com/v2/prices/btc-usd/spot')

  def self.fetch_for_address(address)
    # balance_data = Rails.cache.fetch("blockcypher_balance:#{address}", expires_in: 5.minutes) do
    #   client = BlockCypher::Api.new api_token: Rails.application.credentials.dig(:blockcypher, :token)
    #   client.address_balance(address)
    # end
    client = BlockCypher::Api.new api_token: Rails.application.credentials.dig(:blockcypher, :token)
    balance_data = client.address_balance(address, omit_wallet_addresses: true)

    new(
      address: address,
      satoshis: balance_data.fetch('balance', 0),
      confirmations: balance_data.fetch('confirmations', 0),
      exchange_rate: usd_rate
    )
  rescue SocketError, Net::HTTPError => e
    Rails.logger.error "Failed to fetch Coinbase rate: #{e.message}"
    new(
      address: address,
      satoshis: balance_data.fetch('balance', 0),
      confirmations: balance_data.fetch('confirmations', 0)
    )
  end

  def self.usd_rate
    Rails.cache.fetch("coinbase_btc_usd_rate", expires_in: 10.minutes) do
      response = Net::HTTP.get(COINBASE_URI)
      JSON.parse(response).dig('data', 'amount')&.to_f
    end
  rescue StandardError => e
    Rails.logger.error "Failed to fetch Coinbase rate: #{e.message}"
    nil
  end

  def btc
    (satoshis.to_f / SATOSHIS_PER_BTC).round(8)
  end

  def usd
    return nil unless exchange_rate
    (btc * exchange_rate).round(2)
  end
  alias_method :eur, :usd  # Temporary alias until EUR endpoint is added

  def to_s
    "#{btc} BTC"
  end
end
