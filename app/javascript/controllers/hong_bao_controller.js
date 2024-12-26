import { Controller } from "@hotwired/stimulus"
import BitcoinWallet from "services/bitcoin_wallet"

export default class extends Controller {
  static targets = [
    "step",
    "selectedPaper",
    "stepIndicator",
    "stepConnector",
    "amountDisplay",
    "previousButton",
    "nextButton",
    "verifyButton",
    "paper",
    "paymentMethod",
    "mtPelerinData",
    "walletModal"
  ]

  static values = {
    currentStep: { type: Number, default: 1 },
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

  currentStepValueChanged() {
    this.showCurrentStep()
    this.dispatch("stepChanged", { detail: { currentStep: this.currentStepValue } })
  }

  currentPaperValueChanged() {
    this.paperTargets.forEach(paper => {
      paper.toggleAttribute('open', Number(paper.dataset.paperId) === this.currentPaperValue)
    })
    this.updateURL()
  }

  get currentNextButton() {
    return this.nextButtonTargets.find(button =>
      Number(button.dataset.step) === this.currentStepValue
    )
  }

  nextStep() {
    if (this.currentStepValue < this.stepTargets.length) {
      this.currentStepValue++
    }
  }

  previousStep() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
    }
  }

  paperSelected(event) {
    this.currentPaperValue = Number(event.currentTarget.dataset.paperId)

    if (this.currentNextButton) {
      this.currentNextButton.disabled = false
    }

    this.dispatchPaperSelect(this.currentPaperValue)
  }

  dispatchPaperSelect(paperId) {
    const paperElement = this.paperTargets.find(paper =>
      Number(paper.dataset.paperId) === Number(paperId)
    )

    if (paperElement) {
      this.dispatch("select", {
        detail: {
          paperId: paperElement.dataset.paperId,
          imageFrontUrl: paperElement.dataset.paperCanvaFrontUrl,
          imageBackUrl: paperElement.dataset.paperCanvaBackUrl,
          elements: JSON.parse(paperElement.dataset.paperElements)
        }
      })
    }
  }

  // UI Update Methods
  showCurrentStep() {
    this.updateStepVisibility()
    this.updateProgressSteps()
    this.updateURL()
    this.isTopUpStepValue = (this.currentStepValue === 3)
  }

  updateStepVisibility() {
    this.stepTargets.forEach((step, index) => {
      step.classList.toggle('hidden', index + 1 !== this.currentStepValue)
    })
  }

  updateProgressSteps() {
    this.stepIndicatorTargets.forEach((indicator, index) => {
      const isCurrentStep = index + 1 === this.currentStepValue
      const isDone = index + 1 < this.currentStepValue
      indicator.toggleAttribute('open', isCurrentStep)
      indicator.toggleAttribute('done', isDone)
    })
  }

  updateURL() {
    const url = new URL(window.location)
    url.searchParams.set('step', this.currentStepValue)
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