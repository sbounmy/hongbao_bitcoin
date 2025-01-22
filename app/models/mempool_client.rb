class MempoolClient
  attr_reader :address

  def initialize(address)
    @address = address
    @base_url = address.start_with?("tb1") ? "https://mempool.space/testnet/api" : "https://mempool.space/api"
  end

  def utxos
    current_height = fetch_block_height
    utxo_data = fetch_raw_utxos

    utxo_data.map do |utxo|
      tx_data = fetch_transaction(utxo["txid"])
      Utxo.from_mempool_data(utxo, tx_data, current_height)
    end
  end

  def transactions
    tx_data = fetch_raw_transactions
    tx_data.map { |tx| Transaction.from_mempool_data(tx, address) }
  end

  def fetch_transaction(txid)
    get("/tx/#{txid}")
  end

  def fetch_block_height
    get("/blocks/tip/height").to_i
  end

  private

  def fetch_raw_utxos
    get("/address/#{address}/utxo")
  end

  def fetch_raw_transactions
    get("/address/#{address}/txs")
  end

  def get(path)
    response = Net::HTTP.get(URI("#{@base_url}#{path}"))
    JSON.parse(response)
  rescue StandardError => e
    Rails.logger.error "MempoolClient error: #{e.message}"
    raise
  end
end
