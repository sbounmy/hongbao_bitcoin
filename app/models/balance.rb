require 'net/http'
require 'json'

class Balance
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :satoshis, :integer, default: 0
  attribute :confirmations, :integer, default: 0
  attribute :exchange_rate, :float
  attribute :address, :string
  attribute :confirmed_at, :datetime
  attribute :historical_price, :float

  SATOSHIS_PER_BTC = 100_000_000
  COINBASE_URI = URI('https://api.coinbase.com/v2/prices/btc-usd/spot')

  def self.fetch_for_address(address)
    client = BlockCypher::Api.new api_token: Rails.application.credentials.dig(:blockcypher, :token)
    balance_data = client.address_details(address)

    tx_ref = balance_data.fetch('txrefs', []).first
    Rails.logger.info "Balance data: #{balance_data.inspect}"
    new(
      address: address,
      satoshis: balance_data.fetch('final_balance', 0),
      confirmations: balance_data.fetch('confirmations', 0) || 0,
      exchange_rate: usd_rate,
      confirmed_at: tx_ref&.fetch('confirmed')&.then { |date| Time.parse(date) },
      historical_price: fetch_historical_price(tx_ref&.fetch('confirmed'))
    )
  rescue SocketError, Net::HTTPError => e
    Rails.logger.error "Failed to fetch data: #{e.message}"
    new(address: address)
  end

  def self.fetch_historical_price(date)
    return nil unless date

    date = Date.parse(date).strftime('%Y-%m-%d')
    Rails.cache.fetch("historical_btc_price:#{date}", expires_in: 24.hours) do
      uri = URI("https://api.coinbase.com/v2/prices/BTC-USD/spot?date=#{date}")
      response = Net::HTTP.get(uri)
      JSON.parse(response).dig('data', 'amount')&.to_f
    end
  rescue StandardError => e
    Rails.logger.error "Failed to fetch historical price: #{e.message}"
    nil
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

  def status
    if confirmations.zero? && satoshis > 0
      { icon: :pending, text: 'pending' }
    else
      { icon: :checkmark, text: 'confirmed' }
    end
  end

  def price_change_percentage
    return nil unless historical_price && exchange_rate

    ((exchange_rate - historical_price) / historical_price * 100).round(2)
  end

  def price_info
    return nil unless historical_price && exchange_rate

    {
      purchase_price: historical_price,
      current_price: exchange_rate,
      change_percentage: ((exchange_rate - historical_price) / historical_price * 100).round(2)
    }
  end
end
