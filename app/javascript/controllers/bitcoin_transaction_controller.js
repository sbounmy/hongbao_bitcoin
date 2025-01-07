import { Controller } from "@hotwired/stimulus"
import * as bitcoin from 'bitcoinjs-lib'
import { ECPairFactory } from 'ecpair'
import { initEccLib } from 'bitcoinjs-lib'
import * as secp256k1 from 'secp256k1'
import { Buffer } from 'buffer'

// Initialize the Bitcoin library with secp256k1
initEccLib(secp256k1)

// Make Buffer available globally if needed
if (typeof window !== 'undefined' && !window.Buffer) {
    window.Buffer = Buffer
  }

  // Create ECPair factory with secp256k1
const ECPair = ECPairFactory(secp256k1)

export default class extends Controller {
  static targets = ["toAddress", "privateKey", "form"]
  static values = {
    network: String,
    utxos: Array
  }

  connect() {
    this.network = this.networkValue === 'testnet' ? bitcoin.networks.testnet : bitcoin.networks.bitcoin
  }

  async signAndSubmit(event) {
    event.preventDefault()

    if (!this.validateAddress()) return

    try {
      const signedTx = await this.createSignedTransaction()

      // Add signed transaction to hidden field before submission
      const signedTxInput = document.createElement('input')
      signedTxInput.type = 'hidden'
      signedTxInput.name = 'hong_bao[signed_transaction]'
      signedTxInput.value = signedTx
      this.formTarget.appendChild(signedTxInput)

      // Submit form with signed transaction
      this.formTarget.submit()
    } catch (error) {
      console.error('Transaction signing failed:', error)
      alert('Failed to sign transaction. Please check your private key and try again.')
    }
  }

  validateAddress() {
    try {
      bitcoin.address.toOutputScript(this.toAddressTarget.value, this.network)
      return true
    } catch (error) {
      alert('Invalid Bitcoin address')
      return false
    }
  }

  async createSignedTransaction() {
    const psbt = new bitcoin.Psbt({ network: this.network })

    // Add inputs from UTXOs
    this.utxosValue.forEach(utxo => {
      psbt.addInput({
        hash: utxo.txid,
        index: utxo.vout,
        witnessUtxo: {
          script: Buffer.from(utxo.script, 'hex'),
          value: utxo.value
        }
      })
    })

    // Add output for recipient
    psbt.addOutput({
      address: this.toAddressTarget.value,
      value: this.calculateOutputAmount()
    })

    // Sign all inputs
    const keyPair = ECPair.fromWIF(this.privateKeyTarget.value, this.network)
    psbt.signAllInputs(keyPair)
    psbt.finalizeAllInputs()

    return psbt.extractTransaction().toHex()
  }

  calculateOutputAmount() {
    // Calculate total input amount minus fee
    const totalInput = this.utxosValue.reduce((sum, utxo) => sum + utxo.value, 0)
    const fee = 1000 // Set appropriate fee calculation
    return totalInput - fee
  }
}