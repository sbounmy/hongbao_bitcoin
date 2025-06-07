require "net/http"
require "json"

class Balance
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :address, :string
  attribute :confirmed_at, :datetime

  SATOSHIS_PER_BTC = 100_000_000

  # delegate :transactions, to: :@mempool_client
  # delegate :utxos, to: :@mempool_client

  def initialize(attributes = {})
    super
    @mempool_client = MempoolClient.new(address)
    @blockstream_client = Client::BlockstreamApi.new(dev: false)
  end

  def current_height
    @current_height ||= @blockstream_client.get_tip_height
  end

  def transactions
    @transactions ||= @blockstream_client.get_address_transactions(address).map { |tx| Transaction.from_blockstream_data(tx, address, current_height) }
  end

  def utxos
    @utxos ||= @blockstream_client.get_address_utxos(address)
  end

  def btc
    (satoshis.to_f / SATOSHIS_PER_BTC).round(8)
  end

  def usd
    (btc * Spot.new.to(:usd)).round(2)
  end

  def satoshis
    utxos.sum(&:value)
  end

  def confirmations
    transactions.first&.confirmations || 0
  end


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

  # Returns UTXOs that can be used for creating a transaction
  def utxos_for_transaction
    utxos.map.with_index do |utxo, index|
      {
        hex: index == utxos.count - 1 ? @blockstream_client.get_transaction_hex(utxo.txid) : nil,
        txid: utxo.txid,
        vout: utxo.vout,
        value: utxo.value,
        script: index == utxos.count - 1 ? transactions.last.script : nil
      }
    end
  end
end
