import * as bitcoin from '../../../../vendor/javascript/bitcoinjs-lib.js'
import { ECPairFactory } from 'ecpair'
import * as secp256k1 from '@bitcoinerlab/secp256k1'

export default class BaseTransaction {
  constructor(privateKey, recipientAddress, feeRate, utxos, network = 'testnet') {
    this.privateKey = privateKey
    this.recipientAddress = recipientAddress
    this.feeRate = Math.max(parseInt(feeRate), 1.1)  // minimum 1.1 sats/vbyte
    this.utxos = utxos
    this.networkName = network // 'mainnet' or 'testnet'
    this.network = network === 'mainnet' ? bitcoin.networks.bitcoin : bitcoin.networks.testnet

    // Calculate actual fee based on size and fee rate
    const estimatedSize = this.estimateTransactionSize()
    this.fee = Math.ceil(estimatedSize * this.feeRate)
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
      await this.addInput(psbt, utxo)
    }

    const outputAmount = totalInput - this.fee
    if (outputAmount <= 0) {
      throw new Error(`Insufficient funds. Total input: ${totalInput} sats, Required fee: ${this.fee} sats`)
    }

    // Add output
    psbt.addOutput({
      address: this.recipientAddress,
      value: outputAmount
    })

    await this.signTransaction(psbt)

    psbt.finalizeAllInputs()
    this.rawHex = psbt.extractTransaction().toHex()
    this.txid = psbt.extractTransaction().getId()
    return this
  }

  // Abstract methods to be implemented by child classes
  async addInput(psbt, utxo) {
    throw new Error('Must be implemented by child class')
  }

  estimateTransactionSize() {
    throw new Error('Must be implemented by child class')
  }

  async signTransaction(psbt) {
    const ECPair = ECPairFactory(secp256k1)
    const keyPair = ECPair.fromPrivateKey(this.privateKey)
    const signer = {
      publicKey: Buffer.from(keyPair.publicKey),
      sign: async (hash) => Buffer.from(keyPair.sign(hash))
    }

    for (let i = 0; i < this.utxos.length; i++) {
      await psbt.signInputAsync(i, signer)
    }
  }

  async broadcast() {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content
      const response = await fetch('/hong_baos/transfer', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          raw_hex: this.rawHex,
          network: this.networkName
        })
      })

      if (!response.ok) {
        const error = await response.json()
        throw new Error(`Failed to broadcast: ${error.error}`)
      }

      const data = await response.json()

      return {
        txid: data.txid,
        hex: this.rawHex
      }
    } catch (error) {
      throw new Error(`Broadcasting failed: ${error.message}`)
    }
  }
}