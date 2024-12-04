import { Controller } from "@hotwired/stimulus"

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
    "paymentMethod",
    "mtPelerinData",
    "walletModal",
    "walletInstructions",
    "paper"
  ]

  static values = {
    currentStep: { type: Number, default: 1 },
    currentPaper: { type: Number },
    isTopUpStep: { type: Boolean, default: false }
  }

  connect() {
    this.setupRefreshWarning()
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

  currentStepValueChanged(event) {
    this.showCurrentStep()
    this.updatePreviousButton()
  }

  paperSelected(event) {
    this.currentPaperValue = event.currentTarget.dataset.paperId

    // Dispatch a custom event with paper data
    this.dispatch("select", {
      detail: {
        paperId: event.currentTarget.dataset.paperId,
        imageFrontUrl: event.currentTarget.dataset.paperImageFrontUrl,
        imageBackUrl: event.currentTarget.dataset.paperImageBackUrl,
        elements: JSON.parse(event.currentTarget.dataset.paperElements)
      }
    })
  }

  currentPaperValueChanged(event) {
    this.paperTargets.forEach(paper => {
      paper.toggleAttribute('open', Number(paper.dataset.paperId) === this.currentPaperValue)
    })
    this.updateURL()
  }

  // Navigation Methods
  nextStep() {
    this.currentStepValue++
  }

  previousStep() {
    this.currentStepValue--
  }

  paymentMethodSelected(event) {
    const methodId = event.target.value
    const methodName = event.target.dataset.methodName

    if (methodName === 'mt_pelerin') {
      if (this.hasMtPelerinDataTarget) {
        const data = JSON.parse(this.mtPelerinDataTarget.dataset.options)
        showMtpModal({
          _ctkn: data.ctkn,
          type: 'direct-link',
          lang: data.locale,
          tab: 'buy',
          tabs: 'buy',
          net: data.network,
          nets: data.network,
          curs: 'EUR,USD,SGD',
          ctry: 'FR',
          primary: '#F04747',
          success: '#FFB636',
          amount: data.amount,
          mylogo: data.logo,
          addr: data.address,
          code: data.requestCode,
          hash: data.requestHash
        });
      }
    } else if (['bitstack', 'ledger'].includes(methodName)) {
      this.showWalletInstructions(methodName)
    }
  }

  updatePreviousButton() {
    if (this.currentStepValue > 1) {
      this.previousButtonTarget.style.display = "block"
    } else {
      this.previousButtonTarget.style.display = "none"
    }
  }

  // Add new method to update navigation buttons
  updateNavigationButtons() {
    // Update Previous button
    this.updatePreviousButton()

    // Update Next and Verify buttons
    if (this.currentStepValue === 3) {
      this.nextButtonTarget.style.display = "none"
      this.verifyButtonTarget.style.display = "block"
    } else {
      this.nextButtonTarget.style.display = "block"
      this.verifyButtonTarget.style.display = "none"
    }
  }

  // UI Update Methods
  showCurrentStep() {
    this.updateStepVisibility()
    this.updateProgressSteps()
    this.updateNavigationButtons()
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
    url.searchParams.set('paper_id', this.currentPaperValue)
    window.history.pushState({}, '', url)
  }


  updatePaperPreviews(selectedPaperId) {
    this.element.querySelectorAll('[data-paper-preview][data-paper-id]')
      .forEach(paperDiv => {
        paperDiv.classList.toggle('hidden', paperDiv.dataset.paperId !== selectedPaperId)
      })
  }


  getWalletInstructions(wallet) {
    const qrCode = `<img src="${this.hongBaoQrCode}"
                       alt="Bitcoin Payment QR Code"
                       class="mx-auto mb-4 w-48 h-48">`

    const instructions = {
      bitstack: `
        <h3 class="text-xl font-bold mb-4">Send Bitcoin</h3>
        ${qrCode}
        <div class="space-y-2 text-sm">
          <p>1. Open your Bitcoin wallet</p>
          <p>2. Tap the send button</p>
          <p>3. Scan this QR code or paste the address</p>
          <p>4. Enter the amount and confirm</p>
        </div>

        <div class="mt-4 flex items-center justify-center gap-2 bg-white/10 p-2 rounded">
          <code class="text-sm">${this.hongBaoAddress}</code>
          <button class="btn btn-ghost btn-sm" onclick="navigator.clipboard.writeText('${this.hongBaoAddress}')">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
          </button>
        </div>
      `,
      ledger: `
        <h3 class="text-xl font-bold mb-4">Send Bitcoin</h3>
        ${qrCode}
        <div class="space-y-2 text-sm">
          <p>1. Connect your Ledger device</p>
          <p>2. Open the Bitcoin app</p>
          <p>3. Scan this QR code or paste the address</p>
          <p>4. Verify the address on your device</p>
        </div>

        <div class="mt-4 flex items-center justify-center gap-2 bg-white/10 p-2 rounded">
          <code class="text-sm">${this.hongBaoAddress}</code>
          <button class="btn btn-ghost btn-sm" onclick="navigator.clipboard.writeText('${this.hongBaoAddress}')">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
          </button>
        </div>
      `
    }

    return instructions[wallet]
  }

  get hongBaoAddress() {
    return this.element.querySelector('[data-hong-bao-address]').dataset.hongBaoAddress
  }

  get hongBaoQrCode() {
    return this.element.querySelector('[data-hong-bao-qr-code]').dataset.hongBaoQrCode
  }
}