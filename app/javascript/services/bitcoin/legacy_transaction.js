import Transaction from './transaction'

export default class LegacyTransaction extends Transaction {
  async addInput(psbt, utxo) {
    psbt.addInput({
      hash: utxo.txid,
      index: utxo.vout,
      nonWitnessUtxo: Buffer.from(utxo.hex, 'hex')
    })
  }

  estimateTransactionSize() {
    const overhead = 10  // nVersion, nLocktime
    const inputSize = 148  // ~148 vbytes per P2PKH input
    const outputSize = 34  // ~34 vbytes per P2PKH output
    const outputCount = 1  // We're creating 1 output (recipient)

    return overhead + (inputSize * this.utxos.length) + (outputSize * outputCount)
  }
}