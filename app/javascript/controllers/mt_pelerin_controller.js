import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["iframe"]
  static values = {
    addr: String,
    code: String,
    hash: String
  }

  async walletChanged(event) {
    const { address } = event.detail
    const wallet = window.wallet.getInstance()

    // Generate request code and sign message
    const code = Math.floor(1000 + Math.random() * 9000).toString()
    const hash = wallet.sign(`MtPelerin-${code}`)

    // Update values which will trigger URL update
    this.addrValue = address
    this.codeValue = code
    this.hashValue = hash

    this.dispatch("requestGenerated", {
      detail: {
        addr: this.addrValue,
        code: this.codeValue,
        hash: this.hashValue
      }
    })
  }

  // Automatically called when any value changes
  addrValueChanged() { this.updateIframeUrl() }
  codeValueChanged() { this.updateIframeUrl() }
  hashValueChanged() { this.updateIframeUrl() }

  updateIframeUrl() {
    if (!this.hasIframeTarget || !this.hasAllValues()) return

    const url = new URL(this.iframeTarget.getAttribute("src"))
    url.searchParams.set("addr", this.addrValue)
    url.searchParams.set("code", this.codeValue)
    url.searchParams.set("hash", this.hashValue)

    this.iframeTarget.src = url.toString()
  }

  hasAllValues() {
    return this.addrValue && this.codeValue && this.hashValue
  }
}