import { Controller } from "@hotwired/stimulus"
import WalletFactory from "services/bitcoin/wallet_factory"

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
    this.master = WalletFactory.createDefault({ network: this.networkValue })
    this.wallet = this.master.derive('0')
    this.dispatchWalletChanged()
  }

  new(privateKey, mnemonic) {
    const options = {
      privateKey,
      mnemonic,
      network: this.networkValue
    }

    console.log(options)
    this.wallet = WalletFactory.createDefault(options)
    this.dispatchWalletChanged()
  }

  dispatchWalletChanged() {
    this.dispatch("changed", {
      detail: {
        wallet: this.wallet,
        mnemonic: this.master.mnemonic,
        ...this.wallet.info
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
}