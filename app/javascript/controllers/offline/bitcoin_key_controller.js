import { Controller } from "@hotwired/stimulus"
import * as bitcoin from '../../../../vendor/javascript/bitcoinjs-lib.js'

export default class extends Controller {
  static targets = ["input", "errorMessage"]
  static values = {
    network: { type: String, default: "mainnet" }
  }

  validate() {
    const input = this.inputTarget.value.trim()

    try {
      this._validate(input)
      this.dispatch("success", { detail: { input } })
    } catch (e) {
      console.error(input, e.message)
      this.dispatch("error", { detail: { message: e.message } })
    }
  }

  // Private methods
  _validate(input) {
    throw new Error("Validation not implemented")
  }

  get network() {
    return this.networkValue === "testnet"
      ? bitcoin.networks.testnet
      : bitcoin.networks.bitcoin
  }

    // Helper methods for error handling
    updateErrorMessage(message) {
      if (message) {
        this.errorMessageTarget.textContent = message
        this.errorMessageTarget.classList.remove('hidden')
      } else {
        this.errorMessageTarget.classList.add('hidden')
      }
    }

}