class Transaction
  include ActiveModel::Model

  attr_accessor :id, :timestamp, :amount, :type, :block_height, :address, :confirmations

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
      type: amount.positive? ? "deposit" : "withdrawal",
      confirmations: confirmations,
      block_height: data["status"]["block_height"]
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
    (btc * Spot.new(date: timestamp).to(:usd))
  end

  def eur
    (btc * Spot.new(date: timestamp).to(:eur))
  end

  private

  def self.calculate_amount(data, address)
    outputs = data["vout"].sum { |out| out["scriptpubkey_address"] == address ? out["value"] : 0 }
    inputs = data["vin"].sum { |input| input["prevout"]["scriptpubkey_address"] == address ? input["prevout"]["value"] : 0 }
    outputs - inputs
  end
end
