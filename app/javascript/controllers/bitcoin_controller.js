import { Controller } from "@hotwired/stimulus"
import Master from "services/bitcoin/master"

export default class extends Controller {
  static values = {
    network: { type: String, default: 'mainnet' },
    autoGenerate: { type: Boolean, default: false }
  }

  connect() {
    // BitcoinWallet.setNetwork(this.networkValue)
    if (this.autoGenerateValue) {
      this.generate()
    }
  }

  generate() {
    this.master = Master.generate()
    this.wallet = this.master.derive("m/84'/0'/0'/0/0")
    this.dispatch("changed", {
      detail: {
        wallet: this.wallet,
        mnemonic: this.master.mnemonic,
        ...this.wallet.info
      }
    })
  }

  new(privateKey, mnemonic) {
    this.wallet = Master.new({ privateKey, mnemonic })
    this.dispatch("changed", {
      detail: {
        wallet: this.wallet,
        mnemonic: this.wallet?.mnemonic,
        ...this.getNodeInfo()
      }
    })
  }

  async transfer(address, fee) {
    if (!this.wallet) {
      console.error("No wallet initialized")
      return
    }

    try {
      const transaction = await this.wallet.buildTransaction(address, fee)
      this.dispatch("transfer:success", { detail: result })
    } catch (error) {
      console.error("Error transferring transaction", error)
      this.dispatch("transfer:error", { detail: { error: error.message } })
    }
  }

  // Public API methods that other controllers can use
  sign(message) {
    return this.wallet.sign(message)
  }

  verify(message, signature, address) {
    return this.wallet.verify(message, signature, address)
  }

  getNodeInfo(path = "m/84'/0'/0'/0/0") {
    return this.wallet?.nodePathFor(path)
  }
}