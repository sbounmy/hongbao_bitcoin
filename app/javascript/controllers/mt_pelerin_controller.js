import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    addr: String,
    code: String,
    hash: String,
    ctkn: String,
    rfr: String,
    network: String,
    logo: String,
    primary: String,
    success: String
  }

  async walletChanged(event) {
    const { address } = event.detail
    const wallet = window.wallet.getInstance()

    // Generate request code and sign message
    const code = Math.floor(1000 + Math.random() * 9000).toString()
    const hash = wallet.sign(`MtPelerin-${code}`)

    // Update values
    this.addrValue = address
    this.codeValue = code
    this.hashValue = hash

    // Open modal with updated values
    this.openModal()
  }

  openModal() {
    if (!this.hasAllValues()) return
    console.log(this.ctknValue, this.rfrValue)
    console.log(this.addrValue, this.codeValue, this.hashValue)
    window.showMtpModal({
      lang: document.documentElement.lang || 'en',
      tabs: 'buy',
      tab: 'buy',
      net: this.networkValue,
      nets: this.networkValue,
      curs: 'EUR,USD,SGD',
      bsc: 'EUR',
      ctry: 'FR',
      primary: this.primaryValue,
      success: this.successValue,
      mylogo: this.logoValue,
      addr: this.addrValue,
      code: this.codeValue,
      hash: this.hashValue,
      _ctkn: this.ctknValue,
      rfr: this.rfrValue
    })
  }

  hasAllValues() {
    return this.addrValue && this.codeValue && this.hashValue
  }
}