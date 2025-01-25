import * as bitcoin from 'bitcoinjs-lib'
import { ECPairFactory } from 'ecpair'
import * as secp256k1 from 'secp256k1'

export default class Transaction {
  constructor(privateKey, recipientAddress, feeRate, utxos, network = 'testnet') {
    this.privateKey = privateKey
    this.recipientAddress = recipientAddress
    this.feeRate = Math.max(parseInt(feeRate), 1.1)  // minimum 1.1 sats/vbyte
    this.utxos = utxos
    this.network = network === 'mainnet' ? bitcoin.networks.bitcoin : bitcoin.networks.testnet
    this.baseUrl = network === 'mainnet' ?
      'https://mempool.space/api' :
      'https://mempool.space/testnet/api'

    // Calculate actual fee based on size and fee rate
    const estimatedSize = this.estimateTransactionSize()
    this.fee = Math.ceil(estimatedSize * this.feeRate)
  }

  estimateTransactionSize() {
    // P2WPKH (Native SegWit) transaction size estimation
    const overhead = 10  // nVersion, nLocktime
    const inputSize = 68  // ~68 vbytes per P2WPKH input
    const outputSize = 31  // ~31 vbytes per P2WPKH output
    const outputCount = 1  // We're creating 1 output (recipient)

    return overhead + (inputSize * this.utxos.length) + (outputSize * outputCount)
  }

  async build() {
    if (!this.privateKey) {
      throw new Error('Private key required for transaction building')
    }

    if (!this.utxos || this.utxos.length === 0) {
      throw new Error('No unspent outputs provided')
    }

    const psbt = new bitcoin.Psbt({ network: this.network })

    // Add inputs
    let totalInput = 0
    for (const utxo of this.utxos) {
      totalInput += parseInt(utxo.value)

      if (this.isSegWit(utxo.script)) {
        psbt.addInput({
          hash: utxo.txid,
          index: utxo.vout,
          witnessUtxo: {
            script: Buffer.from(utxo.script, 'hex'),
            value: parseInt(utxo.value)
          }
        })
      } else {
        throw new Error('Non-SegWit inputs are not supported')
      }
    }

    // Calculate output amount (total input - calculated fee)
    const outputAmount = totalInput - this.fee
    console.log('outputAmount', outputAmount)
    console.log('fee', this.fee)
    console.log('feeRate', this.feeRate)
    console.log('estimatedSize', this.estimateTransactionSize())
    console.log('totalInput', totalInput)

    if (outputAmount <= 0) {
      throw new Error(`Insufficient funds. Total input: ${totalInput} sats, Required fee: ${this.fee} sats (${this.feeRate} sats/vb * ${this.estimateTransactionSize()} vbytes)`)
    }

    // Add output
    psbt.addOutput({
      address: this.recipientAddress,
      value: outputAmount
    })

    // Create key pair and signer
    const ECPair = ECPairFactory(secp256k1)
    const keyPair = ECPair.fromPrivateKey(this.privateKey)
    const signer = {
      publicKey: Buffer.from(keyPair.publicKey),
      sign: async (hash) => Buffer.from(keyPair.sign(hash))
    }

    // Sign all inputs
    for (let i = 0; i < this.utxos.length; i++) {
      await psbt.signInputAsync(i, signer)
    }

    psbt.finalizeAllInputs()
    this.rawHex = psbt.extractTransaction().toHex()
    this.txid = psbt.extractTransaction().getId()
    return this
  }

  async broadcast() {
    try {
      const response = await fetch(`${this.baseUrl}/tx`, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/plain',
        },
        body: this.rawHex
      })

      if (!response.ok) {
        const error = await response.text()
        throw new Error(`Failed to broadcast: ${error}`)
      }

      return {
        txid: this.txid,
        hex: this.rawHex
      }
    } catch (error) {
      throw new Error(`Broadcasting failed: ${error.message}`)
    }
  }

  isSegWit(scriptPubKey) {
    const script = Buffer.from(scriptPubKey, "hex")

    if (script.length < 2) return false

    // Check for SegWit version 0 (P2WPKH or P2WSH)
    if (script[0] === 0x00 && (script[1] === 0x14 || script[1] === 0x20)) {
      return true
    }

    // Check for SegWit version 1 (Taproot)
    if (script[0] === 0x01 && script[1] === 0x20) {
      return true
    }

    return false
  }
}