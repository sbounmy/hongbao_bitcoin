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
      tx_hex = fetch_transaction_hex(utxo["txid"])
      Utxo.from_mempool_data(utxo, tx_data, tx_hex, current_height)
    end
  end

  def transactions
    tx_data = fetch_raw_transactions

    # Sort by block_time, putting nil (unconfirmed) first
    sorted_tx_data = tx_data.sort_by do |tx|
      # Use max integer for unconfirmed to ensure they come first
      -(tx["status"]["block_time"] || Float::INFINITY)
    end

    sorted_tx_data.map { |tx| Transaction.from_mempool_data(tx, address, fetch_block_height) }
  end

  def fetch_transaction(txid)
    get("/tx/#{txid}")
  end

  def fetch_transaction_hex(txid)
    get("/tx/#{txid}/hex")
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
    uri = URI("#{@base_url}#{path}")
    response = Net::HTTP.get_response(uri)

    case response.content_type
    when "application/json"
      JSON.parse(response.body)
    when "text/plain"
      response.body
    else
      Rails.logger.warn "Unexpected content type: #{response.content_type} for path: #{path}"
      response.body
    end
  rescue StandardError => e
    Rails.logger.error "MempoolClient error: #{e.message}"
    raise
  end
end
