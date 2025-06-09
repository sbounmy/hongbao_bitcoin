require "net/http"
require "json"

class Balance
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :address, :string
  attribute :confirmed_at, :datetime

  SATOSHIS_PER_BTC = 100_000_000

  def initialize(attributes = {})
    super
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
  # script and hex are needed for transaction creation, not balance, we should do a separate method for that
  def utxos_for_transaction
    utxos.map.with_index do |utxo, index|
      {
        # hex: @blockstream_client.get_transaction_hex(utxo.txid),
        txid: utxo.txid,
        vout: utxo.vout,
        value: utxo.value,
        # script: @blockstream_client.get_transaction(utxo.txid).vout.find { |v| v.scriptpubkey_address == address }.scriptpubkey
      }
    end
  end
end
