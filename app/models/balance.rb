require "net/http"
require "json"

class Balance
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :exchange_rate, :float
  attribute :address, :string
  attribute :confirmed_at, :datetime
  attribute :historical_price, :float

  SATOSHIS_PER_BTC = 100_000_000
  COINBASE_URI = URI("https://api.coinbase.com/v2/prices/btc-usd/spot")

  delegate :transactions, to: :@mempool_client
  delegate :utxos, to: :@mempool_client

  def initialize(attributes = {})
    super
    @mempool_client = MempoolClient.new(address)
  end

  def refresh!
    update_balance_from_utxos
    self
  end

  def btc
    (satoshis.to_f / SATOSHIS_PER_BTC).round(8)
  end

  def satoshis
    utxos.sum(&:value)
  end

  def confirmations
    utxos.first&.confirmations || 0
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
      { icon: :pending, text: "pending" }
    else
      { icon: :checkmark, text: "confirmed" }
    end
  end

  def price_info
    return nil unless historical_price && exchange_rate

    {
      purchase_price: historical_price,
      current_price: exchange_rate,
      change_percentage: price_change_percentage
    }
  end

  # Returns UTXOs that can be used for creating a transaction
  def utxos_for_transaction
    utxos.map do |utxo|
      {
        txid: utxo.txid,
        vout: utxo.vout,
        value: utxo.value,
        script: utxo.script
      }
    end
  end

  private

  def price_change_percentage
    return nil unless historical_price && exchange_rate
    ((exchange_rate - historical_price) / historical_price * 100).round(2)
  end

  def update_balance_from_utxos
    self.satoshis = utxos.sum(&:value)
    self.confirmations = utxos.first&.confirmations || 0
    self.confirmed_at = utxos.first&.confirmed_at
    self.exchange_rate = self.class.usd_rate
    self.historical_price = self.class.fetch_historical_price(confirmed_at&.iso8601)
  end


  class << self
    def fetch_historical_price(date)
      return nil unless date

      date = Date.parse(date).strftime("%Y-%m-%d")
      Rails.cache.fetch("historical_btc_price:#{date}", expires_in: 24.hours) do
        uri = URI("https://api.coinbase.com/v2/prices/BTC-USD/spot?date=#{date}")
        response = Net::HTTP.get(uri)
        JSON.parse(response).dig("data", "amount")&.to_f
      end
    rescue StandardError => e
      Rails.logger.error "Failed to fetch historical price: #{e.message}"
      nil
    end

    def usd_rate
      Rails.cache.fetch("coinbase_btc_usd_rate", expires_in: 10.minutes) do
        response = Net::HTTP.get(COINBASE_URI)
        JSON.parse(response).dig("data", "amount")&.to_f
      end
    rescue StandardError => e
      Rails.logger.error "Failed to fetch Coinbase rate: #{e.message}"
      nil
    end
  end
end
