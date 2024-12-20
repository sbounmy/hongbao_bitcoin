import { Controller } from "@hotwired/stimulus"
import * as bitcoin from 'bitcoinjs-lib'
import { ECPairFactory } from 'ecpair'
import { initEccLib } from 'bitcoinjs-lib'
import * as secp256k1 from '@bitcoinerlab/secp256k1'
import { Buffer } from 'buffer'
import 'bip39'
import { BIP32Factory } from 'bip32'

// Initialize the Bitcoin library with secp256k1 FIRST, before any other bitcoin-related operations
initEccLib(secp256k1)

// Make Buffer available globally
if (typeof window !== 'undefined' && !window.Buffer) {
  window.Buffer = Buffer
}

// Create ECPair factory with the same secp256k1 implementation
const ECPair = ECPairFactory(secp256k1)

// Create BIP32 factory with the same secp256k1 implementation
const bip32 = BIP32Factory(secp256k1)

export default class extends Controller {
  static targets = ["result", "privateKey", "address", "mnemonic"]
  static values = {
    network: { type: String, default: 'testnet' }
  }

  connect() {
    this.network = this.networkValue === 'testnet' ? bitcoin.networks.testnet : bitcoin.networks.bitcoin
  }

  generate() {
    try {
      // Generate mnemonic
      const mnemonic = window.bip39.generateMnemonic()

      // Convert mnemonic to seed
      const seed = window.bip39.mnemonicToSeedSync(mnemonic)

      // Create root node from seed
      const root = bip32.fromSeed(seed)

      // Derive first account's external chain (m/44'/0'/0'/0/0 for mainnet or m/44'/1'/0'/0/0 for testnet)
      const path = this.network === bitcoin.networks.testnet ?
        "m/44'/1'/0'/0/0" : "m/44'/0'/0'/0/0"
      const child = root.derivePath(path)

      // Create ECPair from the derived private key
      const keyPair = ECPair.fromPrivateKey(child.privateKey, { network: this.network })

      // Get WIF private key
      const privateKeyWIF = keyPair.toWIF()

      // Create legacy address (p2pkh)
      const { address } = bitcoin.payments.p2pkh({
        pubkey: Buffer.from(child.publicKey),
        network: this.network
      })

      // Update the UI
      this.privateKeyTarget.value = privateKeyWIF
      this.addressTarget.value = address
      this.mnemonicTarget.value = mnemonic
      this.resultTarget.classList.remove('hidden')
    } catch (error) {
      console.error('Key generation error:', error)
      alert('Failed to generate Bitcoin keypair. Please try again.')
    }
  }

  copy(event) {
    const target = event.currentTarget.dataset.copyTarget
    const text = this[`${target}Target`].value

    if (!text) return // Guard against empty values

    navigator.clipboard.writeText(text).then(() => {
      // Store original content
      const button = event.currentTarget
      const originalContent = button.innerHTML

      // Update with checkmark icon
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
        </svg>
      `

      // Reset after 1 second
      setTimeout(() => {
        button.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
          </svg>
        `
      }, 1000)
    }).catch(err => {
      console.error('Failed to copy text:', err)
    })
  }
}