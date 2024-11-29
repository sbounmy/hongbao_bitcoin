import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step",
    "selectedPaper",
    "stepIndicator",
    "stepConnector",
    "amountDisplay",
    "previousButton"
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

  updatePreviousButton() {
    if (this.currentStepValue > 1) {
      this.previousButtonTarget.style.display = "block"
    } else {
      this.previousButtonTarget.style.display = "none"
    }
  }

  // UI Update Methods
  showCurrentStep() {
    this.updateStepVisibility()
    this.updateStepIndicators()
    this.updateStepConnectors()
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
}