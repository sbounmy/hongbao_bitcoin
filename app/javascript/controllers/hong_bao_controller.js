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
    "paper"
  ]

  static values = {
    currentStep: { type: Number, default: 1 },
    currentPaper: { type: Number },
    isTopUpStep: { type: Boolean, default: false },
    isPdfDownloaded: { type: Boolean, default: false }
  }

  connect() {
    this.setupRefreshWarning()
    this.isPdfDownloaded = false
    document.addEventListener('paper-pdf:pdfDownloaded', () => {
      this.isPdfDownloaded = true
      this.updateNavigationButtons()
    })
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

    // Dispatch an event when the step changes
    this.dispatch("stepChanged", { detail: { currentStep: this.currentStepValue } })
  }

  paperSelected(event) {
    this.currentPaperValue = event.currentTarget.dataset.paperId

    // Dispatch a custom event with paper data
    this.dispatch("select", {
      detail: {
        paperId: event.currentTarget.dataset.paperId,
        imageFrontUrl: event.currentTarget.dataset.paperCanvaFrontUrl,
        imageBackUrl: event.currentTarget.dataset.paperCanvaBackUrl,
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
    event.preventDefault()
    const methodId = event.target.value
    const methodName = event.target.dataset.methodName

    // Hide all wallet modals first
    this.walletModalTargets.forEach(modal => modal.classList.add('hidden'))

    if (methodName === 'mt_pelerin') {
      if (this.hasMtPelerinDataTarget) {
        const data = JSON.parse(this.mtPelerinDataTarget.dataset.options)
        showMtpModal({
          _ctkn: data.ctkn,
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
      // Show the corresponding wallet modal
      const modal = this.walletModalTargets.find(m => m.dataset.walletType === methodName)
      if (modal) modal.classList.remove('hidden')
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
    } else if (this.currentStepValue === 2) {
      this.nextButtonTarget.style.display = "block"
      this.nextButtonTarget.disabled = !this.isPdfDownloaded
      this.nextButtonTarget.classList.toggle('disabled:opacity-50', !this.isPdfDownloaded)
      this.verifyButtonTarget.style.display = "none"
    } else {
      this.nextButtonTarget.style.display = "block"
      this.nextButtonTarget.disabled = false
      this.nextButtonTarget.classList.remove('disabled:opacity-50')
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

  closeWalletModal(event) {
    event.preventDefault()
    this.walletModalTargets.forEach(modal => modal.classList.add('hidden'))
  }

  copyAddress(event) {
    event.preventDefault()
    navigator.clipboard.writeText(this.element.querySelector('[data-hong-bao-address]').dataset.hongBaoAddress)
  }

  cache({ detail: { side, base64url, paperId } }) {
    const paper = this.paperTargets.find(paper => Number(paper.dataset.paperId) === paperId)

    if (side === 'back') {
      paper.dataset.paperCanvaBackUrl = base64url
    } else if (side === 'front') {
      paper.dataset.paperCanvaFrontUrl = base64url
    }
  }
}