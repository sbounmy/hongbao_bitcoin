import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "selectedPaper", "stepIndicator", "stepConnector"]

  connect() {
    const params = new URLSearchParams(window.location.search)
    const stepParam = parseInt(params.get('step') || 1)

    if (stepParam && stepParam <= this.stepTargets.length) {
      this.currentStepValue = stepParam
    }

    this.showCurrentStep()
    this.updatePreview()
  }

  updatePreview() {
    // Update amount display when amount changes
    const amountInput = this.element.querySelector('input[name="hong_bao[amount]"]')
    if (amountInput) {
      amountInput.addEventListener('input', (e) => {
        this.amountDisplayTarget.textContent = parseFloat(e.target.value || 0).toFixed(2)
      })
    }
  }

  selectPaper(event) {
    if (event.target.checked) {
      // Update selected paper preview
      this.paperRadioTargets.forEach(radio => {
        radio.closest('label').classList.toggle('ring-2', radio.checked)
      })

      // Auto-advance to next step after paper selection
      setTimeout(() => this.nextStep(), 300)
    }
  }

  nextStep() {
    console.log("nextStep", this.currentStepValue)
    if (this.currentStepValue < this.stepTargets.length) {
      this.currentStepValue++
      this.showCurrentStep()
    }
  }

  previousStep() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showCurrentStep()
    }
  }

  showCurrentStep() {
    this.stepTargets.forEach((step, index) => {
      step.classList.toggle('hidden', index + 1 !== this.currentStepValue)
    })

    console.log("showCurrentStep", this.stepIndicatorTargets)
    // Update step indicators
    this.stepIndicatorTargets.forEach((indicator, index) => {
      if (index + 1 === this.currentStepValue) {
        indicator.classList.remove('bg-white/20', 'text-white')
        indicator.classList.add('bg-[#FFB636]', 'text-[#F04747]')
      } else {
        indicator.classList.remove('bg-[#FFB636]', 'text-[#F04747]')
        indicator.classList.add('bg-white/20', 'text-white')
      }
    })

    // Update connecting lines
    this.stepConnectorTargets.forEach((connector, index) => {
      if (index + 1 < this.currentStepValue) {
        connector.classList.remove('bg-white/20')
        connector.classList.add('bg-[#FFB636]')
      } else {
        connector.classList.remove('bg-[#FFB636]')
        connector.classList.add('bg-white/20')
      }
    })

    // Update URL with current step
    const url = new URL(window.location)
    url.searchParams.set('step', this.currentStepValue)
    window.history.pushState({}, '', url)
  }

  switchTemplate(event) {
    const paperId = event.currentTarget.dataset.paperId
    this.selectedPaperTarget.value = paperId

    // Update button styles
    this.element.querySelectorAll('[data-action="hong-bao#switchTemplate"]').forEach(button => {
      if (button.dataset.paperId === paperId) {
        button.classList.add('bg-[#FFB636]', 'text-[#F04747]')
        button.classList.remove('bg-white/20', 'text-white')
      } else {
        button.classList.remove('bg-[#FFB636]', 'text-[#F04747]')
        button.classList.add('bg-white/20', 'text-white')
      }
    })

    // Show selected paper preview, hide others
    this.element.querySelectorAll('[data-paper-preview][data-paper-id]').forEach(paperDiv => {
      if (paperDiv.dataset.paperId === paperId) {
        paperDiv.classList.remove('hidden')
      } else {
        paperDiv.classList.add('hidden')
      }
    })
  }
}