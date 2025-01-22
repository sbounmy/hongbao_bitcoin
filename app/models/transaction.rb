class Transaction
  include ActiveModel::Model

  attr_accessor :id, :timestamp, :amount, :type, :block_height, :address

  def self.from_mempool_data(data, address)
    amount = calculate_amount(data, address)

    new(
      id: data["txid"],
      timestamp: Time.at(data["status"]["block_time"]),
      amount: amount,
      address: data["vout"][0]["scriptpubkey_address"],
      type: amount.positive? ? "deposit" : "withdrawal",
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

  private

  def self.calculate_amount(data, address)
    outputs = data["vout"].sum { |out| out["scriptpubkey_address"] == address ? out["value"] : 0 }
    inputs = data["vin"].sum { |input| input["prevout"]["scriptpubkey_address"] == address ? input["prevout"]["value"] : 0 }
    outputs - inputs
  end
end
