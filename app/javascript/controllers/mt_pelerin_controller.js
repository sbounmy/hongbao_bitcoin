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

  open(event) {
    event.preventDefault()
    this.#generateRequest()

    if (!this.#hasAllValues) return

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

  #generateRequest() {
    const { address } = window.wallet.nodePathFor("m/44'/0'/0'/0/0")

    // Generate request code and sign message
    const code = Math.floor(1000 + Math.random() * 9000).toString()
    const hash = window.wallet.sign(`MtPelerin-${code}`)

    // Update values
    this.addrValue = address
    this.codeValue = code
    this.hashValue = hash
  }

  get #hasAllValues() {
    return this.addrValue && this.codeValue && this.hashValue
  }
}