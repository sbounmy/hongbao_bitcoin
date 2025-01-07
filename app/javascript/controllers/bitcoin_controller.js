import { Controller } from "@hotwired/stimulus"
import BitcoinWallet from "services/bitcoin_wallet"

export default class extends Controller {
  static values = {
    network: { type: String, default: 'mainnet' }
  }

  static targets = ["mnemonic", "privateKey", "address"]

  connect() {
    BitcoinWallet.setNetwork(this.networkValue)
    this.generate()
    window.bitcoin = this
  }

  // Public API methods that other controllers can use
  sign(message) {
    return this.wallet.sign(message)
  }

  verify(message, signature, address) {
    return this.wallet.verify(message, signature, address)
  }

  getNodeInfo(path = "m/44'/0'/0'/0/0") {
    return this.wallet.nodePathFor(path)
  }

  generate() {
    this.wallet = BitcoinWallet.generate()
    this.dispatch("changed", {
      detail: {
        wallet: this.wallet,
        mnemonic: this.wallet.mnemonic,
        ...this.getNodeInfo()
      }
    })
  }
}