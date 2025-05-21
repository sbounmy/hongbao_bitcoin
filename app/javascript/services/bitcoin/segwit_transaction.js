import Transaction from './transaction'

export default class SegWitTransaction extends Transaction {
  async addInput(psbt, utxo) {
    psbt.addInput({
      hash: utxo.txid,
      index: utxo.vout,
      witnessUtxo: {
        script: Buffer.from(utxo.script, 'hex'),
        value: parseInt(utxo.value)
      }
    })
  }

  estimateTransactionSize() {
    const overhead = 10  // nVersion, nLocktime
    const inputSize = 68  // ~68 vbytes per P2WPKH input
    const outputSize = 31  // ~31 vbytes per P2WPKH output
    const outputCount = 1  // We're creating 1 output (recipient)

    return overhead + (inputSize * this.utxos.length) + (outputSize * outputCount)
  }
}