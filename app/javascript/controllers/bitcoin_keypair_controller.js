import { Controller } from "@hotwired/stimulus"
import BitcoinWallet from "services/bitcoin_wallet"

export default class extends Controller {
  static targets = ["result", "privateKey", "address", "mnemonic", "mtPelerinCode", "mtPelerinHash"]
  static values = {
    network: { type: String, default: 'testnet' }
  }

  connect() {
    this.wallet = new BitcoinWallet(this.networkValue)
    this.generate()
  }

  async generate() {
    try {
      const keyPair = await this.wallet.generateKeyPair()
      const mtPelerin = await this.wallet.generateMtPelerinRequest()

      this.updateUI(keyPair, mtPelerin)
      this.resultTarget.classList.remove('hidden')

      this.dispatch('generated', {
        detail: {
          ...keyPair,
          ...mtPelerin
        }
      })
    } catch (error) {
      console.error('Key generation error:', error)
      alert('Failed to generate Bitcoin keypair. Please try again.')
    }
  }

  updateUI(keyPair, mtPelerin) {
    this.privateKeyTarget.value = keyPair.privateKeyWIF
    this.addressTarget.value = keyPair.address
    this.mnemonicTarget.value = keyPair.mnemonic
    this.mtPelerinCodeTarget.value = mtPelerin.requestCode
    this.mtPelerinHashTarget.value = mtPelerin.requestHash
  }
}