import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["iframe"]

  update(event) {
    if (!event.detail.wallet.mtPelerin) return

    const wallet = event.detail.wallet
    const address = event.detail.publicAddressText
    const code = Math.floor(1000 + Math.random() * 9000).toString()
    const hash = wallet.sign(`MtPelerin-${code}`)

    const params = new URLSearchParams(this.iframeTarget.src.split('?')[1])
    params.set('addr', address)
    params.set('code', code)
    params.set('hash', hash)

    this.iframeTarget.src = `https://widget.mtpelerin.com/?${params}`
  }
}