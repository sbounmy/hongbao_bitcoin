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
    "walletInstructions"
  ]

  static values = {
    currentStep: { type: Number, default: 1 }
  }

  connect() {
    this.initializeStep()
    this.initializeAmountListener()
    this.showCurrentStep()
    this.updatePreviousButton()
  }

  // Private Methods
  initializeStep() {
    const stepParam = parseInt(new URLSearchParams(window.location.search).get('step') || 1)
    if (stepParam && stepParam <= this.stepTargets.length) {
      this.currentStepValue = stepParam
    }
    this.showCurrentStep()
  }

  initializeAmountListener() {
    const amountInput = this.element.querySelector('input[name="hong_bao[amount]"]')
    if (!amountInput) return

    amountInput.addEventListener('input', (e) => {
      if (this.hasAmountDisplayTarget) {
        this.amountDisplayTarget.textContent = this.formatAmount(e.target.value)
      }
    })
  }

  formatAmount(value) {
    return parseFloat(value || 0).toFixed(2)
  }

  // Navigation Methods
  nextStep() {
    if (this.currentStepValue < 3) {
      this.currentStepValue++
      this.showCurrentStep()
      this.updatePreviousButton()
    }
  }

  previousStep() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showCurrentStep()
      this.updatePreviousButton()
    }
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
    this.updateStepIndicators()
    this.updateStepConnectors()
    this.updateNavigationButtons()
    this.updateURL()
  }

  updateStepVisibility() {
    this.stepTargets.forEach((step, index) => {
      step.classList.toggle('hidden', index + 1 !== this.currentStepValue)
    })
  }

  updateStepIndicators() {
    this.stepIndicatorTargets.forEach((indicator, index) => {
      const isCurrentStep = index + 1 === this.currentStepValue
      indicator.classList.toggle('bg-[#FFB636]', isCurrentStep)
      indicator.classList.toggle('text-[#F04747]', isCurrentStep)
      indicator.classList.toggle('bg-white/20', !isCurrentStep)
      indicator.classList.toggle('text-white', !isCurrentStep)
    })
  }

  updateStepConnectors() {
    this.stepConnectorTargets.forEach((connector, index) => {
      const isCompleted = index + 1 < this.currentStepValue
      connector.classList.toggle('bg-[#FFB636]', isCompleted)
      connector.classList.toggle('bg-white/20', !isCompleted)
    })
  }

  updateURL() {
    const url = new URL(window.location)
    url.searchParams.set('step', this.currentStepValue)
    window.history.pushState({}, '', url)
  }

  // Template Selection Methods
  switchTemplate(event) {
    const paperId = event.currentTarget.dataset.paperId
    this.selectedPaperTarget.value = paperId

    this.updateTemplateButtons(paperId)
    this.updatePaperPreviews(paperId)
  }

  updateTemplateButtons(selectedPaperId) {
    this.element.querySelectorAll('[data-action="hong-bao#switchTemplate"]')
      .forEach(button => {
        const isSelected = button.dataset.paperId === selectedPaperId
        button.classList.toggle('bg-[#FFB636]', isSelected)
        button.classList.toggle('text-[#F04747]', isSelected)
        button.classList.toggle('bg-white/20', !isSelected)
        button.classList.toggle('text-white', !isSelected)
      })
  }

  updatePaperPreviews(selectedPaperId) {
    this.element.querySelectorAll('[data-paper-preview][data-paper-id]')
      .forEach(paperDiv => {
        paperDiv.classList.toggle('hidden', paperDiv.dataset.paperId !== selectedPaperId)
      })
  }

  showWalletInstructions(wallet) {
    if (this.hasWalletModalTarget && this.hasWalletInstructionsTarget) {
      // Set wallet-specific content
      const instructions = this.getWalletInstructions(wallet)
      this.walletInstructionsTarget.innerHTML = instructions

      // Show modal
      this.walletModalTarget.classList.remove('hidden')
    }
  }

  hideWalletModal() {
    if (this.hasWalletModalTarget) {
      this.walletModalTarget.classList.add('hidden')
    }
  }

  getWalletInstructions(wallet) {
    const qrCode = `<img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${this.hongBaoAddress}"
                       alt="Bitcoin Address QR Code" class="mx-auto mb-4">`

    const instructions = {
      bitstack: `
        <h3 class="text-lg font-bold mb-4">Send with Bitstack</h3>
        ${qrCode}
        <ol class="list-decimal list-inside space-y-2 text-sm">
          <li>Open your Bitstack wallet</li>
          <li>Tap the send button</li>
          <li>Scan this QR code or paste the address</li>
          <li>Enter the amount and confirm</li>
        </ol>
      `,
      ledger: `
        <h3 class="text-lg font-bold mb-4">Send with Ledger</h3>
        ${qrCode}
        <ol class="list-decimal list-inside space-y-2 text-sm">
          <li>Connect your Ledger device</li>
          <li>Open the Bitcoin app</li>
          <li>Use Ledger Live to send</li>
          <li>Verify the address on your device</li>
        </ol>
      `
    }

    return instructions[wallet]
  }

  get hongBaoAddress() {
    return this.element.querySelector('[data-hong-bao-address]').dataset.hongBaoAddress
  }
}