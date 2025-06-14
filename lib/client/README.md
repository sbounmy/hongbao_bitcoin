# Blockstream API Client 🚀

A Ruby client for interacting with the Blockstream Esplora API, providing easy access to Bitcoin blockchain data for the Balance model.

## Setup 📋

**Initialize the client**:
```ruby
# For Bitcoin mainnet
client = Client::BlockstreamApi.new(dev: false)

# For Bitcoin testnet
client = Client::BlockstreamApi.new(dev: true)
```

The client automatically uses the correct endpoints:
- **Mainnet**: `https://blockstream.info/api`
- **Testnet**: `https://blockstream.info/testnet/api`

## Usage Examples 💡

### Address Information
```ruby
# Initialize client for mainnet
client = Client::BlockstreamApi.new(dev: false)

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
  # Note: UTXOs from Blockstream API do NOT include scriptPubKey
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
puts "Output scripts: #{transaction.vout.map(&:scriptpubkey)}"

# Get transaction hex for spending UTXOs
hex = client.get_transaction_hex(txid)
puts "Transaction hex: #{hex}"

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
- `get_address_utxos(address)` - Unspent transaction outputs ⚠️ **No script field**

### Transaction Endpoints (Transaction Details)
- `get_transaction(txid)` - Full transaction details with scriptPubKeys
- `get_transaction_status(txid)` - Transaction confirmation status
- `get_transaction_hex(txid)` - Raw transaction hex for spending UTXOs

### Block Endpoints (Confirmations Calculation)
- `get_tip_height` - Latest block height

## ⚠️ Known Limitations

### UTXO Script Limitation
**Important**: Blockstream's UTXO endpoint does NOT include the `scriptPubKey` field that's required for transaction creation. This is different from Mempool.space API which includes scripts.

**Workaround**: The Balance model handles this by:
1. Getting transaction details to extract scripts from outputs
2. Using a hybrid approach with MempoolClient for UTXOs when scripts are needed

```ruby
# This WON'T work - no script field
utxos = client.get_address_utxos(address)
puts utxos.first.script  # NoMethodError!

# This WILL work - get script from transaction
utxos = client.get_address_utxos(address)
tx = client.get_transaction(utxos.first.txid)
script = tx.vout[utxos.first.vout].scriptpubkey
```

## Response Objects 🎯

Responses are automatically converted to dynamic Ruby objects:

```ruby
# Access nested data easily
transaction = client.get_transaction(txid)
puts transaction.vin.first.txid  # Input transaction ID
puts transaction.vout.first.value  # Output value in satoshis
puts transaction.vout.first.scriptpubkey  # Script for this output

# Array responses become ListObjects with enumerable methods
txs = client.get_address_transactions(address)
txs.each { |tx| puts tx.txid }
puts txs.count # Number of transactions

# Check confirmation status
puts transaction.status.confirmed  # true/false
puts transaction.status.block_height  # Block height if confirmed
```

## Integration with Balance Model 🔗

Current integration in the Balance model:

```ruby
# In balance.rb
def initialize(attributes = {})
  super
  @mempool_client = MempoolClient.new(address)
  @blockstream_client = Client::BlockstreamApi.new(dev: false)
end

# Use blockstream for transactions (faster, more reliable)
def transactions
  @transactions ||= @blockstream_client.get_address_transactions(address)
    .map { |tx| Transaction.from_blockstream_data(tx, address, current_height) }
end

# Use blockstream for UTXOs
def utxos
  @utxos ||= @blockstream_client.get_address_utxos(address)
end

# Handle script requirement for transaction creation
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

def current_height
  @current_height ||= @blockstream_client.get_tip_height
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
- Dev/production initialization
- Address information and stats
- Transaction lists and details
- UTXOs retrieval (without scripts)
- Block height for confirmations
- Transaction hex for spending

## Comparison with Mempool.space API 📊

| Feature | Blockstream | Mempool.space |
|---------|-------------|---------------|
| UTXO endpoint | ✅ Fast | ✅ Fast |
| UTXO scripts | ❌ Not included | ✅ Included |
| Transaction details | ✅ Complete | ✅ Complete |
| Rate limits | ✅ Generous | ⚠️ More restrictive |
| Reliability | ✅ Very stable | ✅ Stable |

**Recommendation**: Use Blockstream for most operations, fall back to Mempool for UTXO scripts when needed.

---

Built with ❤️ for the Hong Bao Bitcoin project using the modular client architecture pattern.