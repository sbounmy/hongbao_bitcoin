import { Controller } from "@hotwired/stimulus"
import * as bitcoin from 'bitcoinjs-lib'

export default class extends Controller {
  static targets = ["input"]
  static values = {
    network: { type: String, default: "mainnet" }
  }

  validate() {
    const input = this.inputTarget.value.trim()

    try {
      this._validate(input)
      console.log('success', input)
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

  get _network() {
    return this.networkValue === "testnet"
      ? bitcoin.networks.testnet
      : bitcoin.networks.bitcoin
  }
}