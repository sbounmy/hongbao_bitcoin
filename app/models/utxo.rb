class Utxo
  include ActiveModel::Model

  attr_accessor :txid, :vout, :value, :script, :confirmations, :confirmed_at

  def self.from_mempool_data(data, tx_data, current_height)
    confirmations = data["status"]["block_height"] ?
      current_height - data["status"]["block_height"] + 1 : 0

    new(
      txid: data["txid"],
      vout: data["vout"],
      value: data["value"],
      script: tx_data["vout"][data["vout"]]["scriptpubkey"],
      confirmations: confirmations,
      confirmed_at: data["status"]["block_time"] ? Time.at(data["status"]["block_time"]) : nil
    )
  end
end
