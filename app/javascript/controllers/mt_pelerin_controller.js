import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["iframe"]

  connect() {
    this.updateIframeSrc()
  }

  updateIframeSrc() {
    const { address } = window.wallet.nodePathFor("m/44'/0'/0'/0/0")
    const code = Math.floor(1000 + Math.random() * 9000).toString()
    const hash = window.wallet.sign(`MtPelerin-${code}`)

    const params = new URLSearchParams(this.iframeTarget.src.split('?')[1])
    params.set('addr', address)
    params.set('code', code)
    params.set('hash', hash)

    this.iframeTarget.src = `https://widget.mtpelerin.com/?${params}`
  }
}