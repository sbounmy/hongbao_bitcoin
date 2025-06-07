# Blockstream API Client 🚀

A Ruby client for interacting with the Blockstream Esplora API, providing easy access to Bitcoin blockchain data needed for the Balance model.

## Setup 📋

**Initialize the client**:
```ruby
# For Bitcoin mainnet
client = Client::BlockstreamApi.new(testnet: false)

# For Bitcoin testnet
client = Client::BlockstreamApi.new(testnet: true)
```

The client automatically uses the correct endpoints:
- **Mainnet**: `https://blockstream.info/api`
- **Testnet**: `https://blockstream.info/testnet/api`

## Usage Examples 💡

### Address Information
```ruby
# Initialize client for mainnet
client = Client::BlockstreamApi.new(testnet: false)

# Get address details
address_info = client.get_address("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
puts "Total received: #{address_info.chain_stats.funded_txo_sum} satoshis"
puts "Address: #{address_info.address}"

# Get address transactions
transactions = client.get_address_transactions("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
transactions.each do |tx|
  puts "TX: #{tx.txid}, Confirmed: #{tx.status.confirmed}"
end

# Get unspent outputs (UTXOs)
utxos = client.get_address_utxos("1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
utxos.each do |utxo|
  puts "UTXO: #{utxo.value} satoshis in #{utxo.txid}:#{utxo.vout}"
end
```

### Transaction Data
```ruby
txid = "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"

# Get full transaction details
transaction = client.get_transaction(txid)
puts "Confirmed: #{transaction.status.confirmed}"
puts "Inputs: #{transaction.vin.length}"
puts "Outputs: #{transaction.vout.length}"

# Get just transaction status
status = client.get_transaction_status(txid)
puts "Block height: #{status.block_height}"
puts "Block time: #{status.block_time}"
```

### Block Information
```ruby
# Get current blockchain tip height
tip_height = client.get_tip_height
puts "Current block height: #{tip_height}"
```

## Available Methods 📚

### Address Endpoints (Core Balance Functionality)
- `get_address(address)` - Address information and stats
- `get_address_transactions(address)` - List of address transactions
- `get_address_utxos(address)` - Unspent transaction outputs

### Transaction Endpoints (Transaction Details)
- `get_transaction(txid)` - Full transaction details
- `get_transaction_status(txid)` - Transaction confirmation status

### Block Endpoints (Confirmations Calculation)
- `get_tip_height` - Latest block height

## Response Objects 🎯

Responses are automatically converted to dynamic Ruby objects:

```ruby
# Access nested data easily
transaction = client.get_transaction(txid)
puts transaction.vin.first.txid  # Input transaction ID
puts transaction.vout.first.value  # Output value in satoshis

# Array responses become ListObjects with enumerable methods
txs = client.get_address_transactions(address)
txs.each { |tx| puts tx.txid }
puts txs.count # Number of transactions

# Check confirmation status
puts transaction.status.confirmed  # true/false
puts transaction.status.block_height  # Block height if confirmed
```

## Integration with Balance Model 🔗

This client is designed to work seamlessly with the Balance model to replace the current MempoolClient:

```ruby
# In balance.rb
def initialize(attributes = {})
  super
  testnet = address.start_with?("tb1") || address.start_with?("2") || address.start_with?("n") || address.start_with?("m")
  @blockstream_client = Client::BlockstreamApi.new(testnet: testnet)
end

def utxos
  current_height = @blockstream_client.get_tip_height.to_i
  utxo_data = @blockstream_client.get_address_utxos(address)
  # Process UTXOs...
end

def transactions
  tx_data = @blockstream_client.get_address_transactions(address)
  # Process transactions...
end
```

## Error Handling 🛡️

```ruby
begin
  result = client.get_transaction("invalid_txid")
rescue => e
  puts "API Error: #{e.message}"
end
```

## Testing 🧪

Run the focused test suite:
```bash
bundle exec rspec spec/lib/client/blockstream_api_spec.rb
```

The client includes test coverage for:
- Testnet/mainnet initialization
- Address information and stats
- Transaction lists and details
- UTXOs retrieval
- Block height for confirmations

---

Built with ❤️ for the Hong Bao Bitcoin project using the modular client architecture pattern.