import { Controller } from "@hotwired/stimulus"
import BitcoinWallet from "services/bitcoin_wallet"

export default class extends Controller {
  static targets = [
    "paper",
    "paymentMethod",
    "mtPelerinData",
    "walletModal"
  ]

  static values = {
    currentPaper: { type: Number },
    wallet: { type: Object, default: {} }
  }

  connect() {
    this.setupRefreshWarning()
    this.generateWallet()
  }

  async generateWallet() {
    const wallet = BitcoinWallet.generate()
    const key = wallet.nodePathFor("m/44'/0'/0'/0/0")

    // Generate Mt Pelerin request if needed
    const mtPelerin = await wallet.generateMtPelerinRequest()

    this.walletValue = {
      address: key.address,
      privateKey: key.privateKey,
      mnemonic: wallet.mnemonic,
      addressQrcode: await key.addressQrcode(),
      privateKeyQrcode: await key.privateKeyQrcode(),
      publicKeyQrcode: await key.publicKeyQrcode(),
      mtPelerinCode: mtPelerin.requestCode,
      mtPelerinHash: mtPelerin.requestHash
    }
  }

  walletValueChanged() {
    console.log('hasMnemonicTarget:', this.hasMnemonicTarget)
    if (this.hasMnemonicTarget) {
      this.mnemonicTarget.value = this.walletValue.mnemonic
    }
    if (this.hasPrivateKeyTarget) {
      this.privateKeyTarget.value = this.walletValue.privateKey
    }
    if (this.hasAddressTarget) {
      this.addressTarget.value = this.walletValue.address
    }

    // Dispatch event for other controllers
    this.dispatch("walletChanged", { detail: this.walletValue })
  }

  setupRefreshWarning() {
    window.addEventListener('beforeunload', (e) => this.handleBeforeUnload(e))
  }

  disconnect() {
    window.removeEventListener('beforeunload', (e) => this.handleBeforeUnload(e))
  }

  handleBeforeUnload(e) {
    if (this.isTopUpStepValue) {
      e.preventDefault()
      e.returnValue = ''
      return ''
    }
  }

  currentPaperValueChanged() {
    this.paperTargets.forEach(paper => {
      paper.toggleAttribute('open', Number(paper.dataset.paperId) === this.currentPaperValue)
    })
    this.#updateURL()
  }

  paperSelected(event) {
    this.currentPaperValue = Number(event.currentTarget.dataset.paperId)
    this.dispatchPaperSelect()
  }

  get currentPaper() {
    return this.paperTargets.find(paper =>
      Number(paper.dataset.paperId) === Number(this.currentPaperValue)
    )
  }

  dispatchPaperSelect() {

    if (this.currentPaper) {
      this.dispatch("select", {
        detail: {
          paperId: this.currentPaper.dataset.paperId,
          imageFrontUrl: this.currentPaper.dataset.paperCanvaFrontUrl,
          imageBackUrl: this.currentPaper.dataset.paperCanvaBackUrl,
          elements: JSON.parse(this.currentPaper.dataset.paperElements)
        }
      })
    }
  }

  #updateURL() {
    const url = new URL(window.location)
    if (this.currentPaperValue) {
      url.searchParams.set('paper_id', this.currentPaperValue)
    }
    window.history.pushState({}, '', url)
  }

  cache({ detail: { side, base64url, paperId } }) {
    const paper = this.paperTargets.find(paper => Number(paper.dataset.paperId) === Number(paperId))
    if (paper) {
      if (side === 'back') {
        paper.dataset.paperCanvaBackUrl = base64url
      } else if (side === 'front') {
        paper.dataset.paperCanvaFrontUrl = base64url
      }
    }
    if (paper.dataset.paperCanvaFrontUrl &&
      paper.dataset.paperCanvaBackUrl &&
      Number(paperId) === this.currentPaperValue) {
      this.dispatchPaperSelect(paperId)
    }
  }
}