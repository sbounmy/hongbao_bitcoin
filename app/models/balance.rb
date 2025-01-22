require "net/http"
require "json"

class Balance
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :satoshis, :integer, default: 0
  attribute :confirmations, :integer, default: 0
  attribute :exchange_rate, :float
  attribute :address, :string
  attribute :confirmed_at, :datetime
  attribute :historical_price, :float
  attribute :utxos
  attribute :transactions, array: true, default: []

  SATOSHIS_PER_BTC = 100_000_000
  COINBASE_URI = URI("https://api.coinbase.com/v2/prices/btc-usd/spot")

  attr_accessor :utxos

  def initialize(attributes = {})
    @utxos = []
    super
  end

  def self.fetch_for_address(address)
    base_url = address.start_with?("tb1") ? "https://mempool.space/testnet/api" : "https://mempool.space/api"

    # Fetch address UTXOs
    utxos_uri = URI("#{base_url}/address/#{address}/utxo")
    utxos_response = Net::HTTP.get(utxos_uri)
    utxo_data = JSON.parse(utxos_response)

    # Calculate total balance from UTXOs
    total_balance = utxo_data.sum { |utxo| utxo["value"] }

    # Get latest block height for confirmation calculation
    height_uri = URI("#{base_url}/blocks/tip/height")
    current_height = Net::HTTP.get(height_uri).to_i

    # Transform UTXOs into our format
    formatted_utxos = utxo_data.map do |utxo|
      # Fetch transaction details to get script hex
      tx_uri = URI("#{base_url}/tx/#{utxo["txid"]}")
      tx_response = Net::HTTP.get(tx_uri)
      tx_data = JSON.parse(tx_response)

      # Get the script for this specific output
      script_hex = tx_data["vout"][utxo["vout"]]["scriptpubkey"]

      confirmations = utxo["status"]["block_height"] ? current_height - utxo["status"]["block_height"] + 1 : 0
      {
        txid: utxo["txid"],
        vout: utxo["vout"],
        value: utxo["value"],
        script: script_hex,
        confirmations: confirmations
      }
    end

    # Get confirmation count from the first UTXO (if any)
    first_utxo = utxo_data.first
    confirmations = if first_utxo && first_utxo["status"]["block_height"]
      current_height - first_utxo["status"]["block_height"] + 1
    else
      0
    end

    # Get confirmed timestamp from first confirmed UTXO
    confirmed_at = if first_utxo && first_utxo["status"]["block_time"]
      Time.at(first_utxo["status"]["block_time"])
    end

    # Fetch address transactions
    txs_uri = URI("#{base_url}/address/#{address}/txs")
    txs_response = Net::HTTP.get(txs_uri)
    tx_data = JSON.parse(txs_response)

    # Process transactions
    transactions = tx_data.map do |tx|
      # Calculate the net amount for this address
      amount = tx["vout"].sum { |out| out["scriptpubkey_address"] == address ? out["value"] : 0 } -
               tx["vin"].sum { |input| input["prevout"]["scriptpubkey_address"] == address ? input["prevout"]["value"] : 0 }

      {
        txid: tx["txid"],
        timestamp: Time.at(tx["status"]["block_time"]),
        amount: amount,
        type: amount.positive? ? "deposit" : "withdrawal",
        block_height: tx["status"]["block_height"]
      }
    end

    new(
      address: address,
      satoshis: total_balance,
      confirmations: confirmations,
      exchange_rate: usd_rate,
      confirmed_at: confirmed_at,
      historical_price: fetch_historical_price(confirmed_at&.iso8601),
      utxos: formatted_utxos,
      transactions: transactions
    )
  rescue SocketError, Net::HTTPError => e
    Rails.logger.error "Failed to fetch data from mempool.space: #{e.message}"
    new(address: address)
  end

  def self.fetch_historical_price(date)
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

  def self.usd_rate
    Rails.cache.fetch("coinbase_btc_usd_rate", expires_in: 10.minutes) do
      response = Net::HTTP.get(COINBASE_URI)
      JSON.parse(response).dig("data", "amount")&.to_f
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
      { icon: :pending, text: "pending" }
    else
      { icon: :checkmark, text: "confirmed" }
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

  def utxos_for_transaction
    utxos.map do |utxo|
      {
        txid: utxo[:txid],
        vout: utxo[:vout],
        script: utxo[:script],
        value: utxo[:value]
      }
    end
  end
end
