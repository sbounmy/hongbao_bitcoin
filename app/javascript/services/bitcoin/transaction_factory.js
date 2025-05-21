import SegWitTransaction from './segwit_transaction'
import LegacyTransaction from './legacy_transaction'

export default class TransactionFactory {
  static create(privateKey, recipientAddress, feeRate, utxos, network = 'testnet') {
    // Check the first UTXO's script type to determine transaction type
    // We assume all UTXOs are of the same type in a transaction
    const firstUtxo = utxos[0]

    if (this.isSegWitScript(firstUtxo.script)) {
      return new SegWitTransaction(privateKey, recipientAddress, feeRate, utxos, network)
    } else {
      return new LegacyTransaction(privateKey, recipientAddress, feeRate, utxos, network)
    }
  }

  static isSegWitScript(scriptPubKey) {
    const script = Buffer.from(scriptPubKey, "hex")

    if (script.length < 2) return false

    // Check for native SegWit (starts with OP_0 + push bytes)
    if (script[0] === 0x00 && (script[1] === 0x14 || script[1] === 0x20)) {
      return true
    }

    // Check for Taproot (starts with OP_1 + 32 bytes)
    if (script[0] === 0x01 && script[1] === 0x20) {
      return true
    }

    return false
  }
}