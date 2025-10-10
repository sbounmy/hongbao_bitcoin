class Transaction
  include ActiveModel::Model

  attr_accessor :id, :timestamp, :amount, :type, :block_height, :address, :confirmations, :script, :user_address, :raw_data

  SATOSHIS_PER_BTC = 100_000_000

  def self.from_mempool_data(data, address, current_height)
    amount = calculate_amount(data, address)
    confirmations = data["status"]["block_height"] ?
    current_height - data["status"]["block_height"] + 1 : 0

    new(
      id: data["txid"],
      timestamp: data["status"]["block_time"] ? Time.at(data["status"]["block_time"]) : nil,
      amount: amount,
      address: data["vout"][0]["scriptpubkey_address"],
      user_address: address,
      confirmations: confirmations,
      block_height: data["status"]["block_height"],
      raw_data: data
    )
  end

  def self.from_blockstream_data(data, address, current_height)
    new(
      id: data.txid,
      timestamp: data.status.confirmed ? Time.at(data.status.block_time) : nil,
      amount: calculate_amount_from_blockstream_data(data, address),
      address: data.vout.first.scriptpubkey_address,
      user_address: address,
      confirmations: data.status.confirmed ? current_height - data.status.block_height + 1 : 0,
      block_height: data.status.try(:block_height),
      script: data.vout.last.scriptpubkey,
      raw_data: data
      )
  end

  def date
    timestamp.strftime("%B/%d/%Y %H:%M")
  end

  def pretty_id
    id[0..6] + "..." + id[-6..-1]
  end

  def pretty_address
    address[0..6] + "..." + address[-6..-1]
  end

  def btc
    (amount.to_f / SATOSHIS_PER_BTC).round(8)
  end

  def usd
    (btc * (spot&.usd || 0))
  end

  def eur
    (btc * (spot&.eur || 0))
  end

  def spot
    @spot ||= Spot.find_by(date: timestamp)
  end

  def deposit?
    amount.positive?
  end

  def withdrawal?
    amount.negative?
  end

  def from_address
    return address unless has_transaction_data?

    deposit? ? sender_address : user_address
  end

  def to_address
    return address unless has_transaction_data?

    deposit? ? user_address : recipient_address
  end

  def pretty_from_address
    prettify_address(from_address)
  end

  def pretty_to_address
    prettify_address(to_address)
  end

  private

  def has_transaction_data?
    raw_data && user_address
  end

  def sender_address
    find_external_input_address || first_input_address
  end

  def recipient_address
    find_external_output_address || first_output_address
  end

  def find_external_input_address
    inputs.find { |input| input_address(input) != user_address }&.then { |input| input_address(input) }
  end

  def find_external_output_address
    outputs.find { |output| output_address(output) != user_address }&.then { |output| output_address(output) }
  end

  def first_input_address
    input_address(inputs.first)
  end

  def first_output_address
    output_address(outputs.first)
  end

  def inputs
    blockstream_format? ? raw_data.vin : raw_data["vin"]
  end

  def outputs
    blockstream_format? ? raw_data.vout : raw_data["vout"]
  end

  def input_address(input)
    blockstream_format? ? input.prevout.scriptpubkey_address : input["prevout"]["scriptpubkey_address"]
  end

  def output_address(output)
    blockstream_format? ? output.scriptpubkey_address : output["scriptpubkey_address"]
  end

  def blockstream_format?
    raw_data.respond_to?(:vin)
  end

  def prettify_address(addr)
    return "" unless addr
    "#{addr[0..6]}...#{addr[-6..-1]}"
  end

  def self.calculate_amount_from_blockstream_data(data, address)
    outputs = data.vout.sum { |vout| vout["scriptpubkey_address"] == address ? vout["value"] : 0 }
    inputs = data.vin.sum { |vin| vin["prevout"]["scriptpubkey_address"] == address ? vin["prevout"]["value"] : 0 }
    outputs - inputs
  end

  def self.calculate_amount(data, address)
    outputs = data["vout"].sum { |out| out["scriptpubkey_address"] == address ? out["value"] : 0 }
    inputs = data["vin"].sum { |input| input["prevout"]["scriptpubkey_address"] == address ? input["prevout"]["value"] : 0 }
    outputs - inputs
  end
end
