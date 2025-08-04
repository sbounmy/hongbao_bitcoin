import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "indicator", "progress", "counterCurrent", "counterTotal", "previousButton"]
  static classes = ["hidden"]
  static values = {
    current: Number,
  }

  connect() {
    this.#showCurrent()
  }

  next(event) {
    this.currentValue++
  }

  previous(event) {
    if (this.currentValue <= 1) return;
    this.currentValue--
  }


  currentValueChanged() {
    this.#showCurrent()
    this.dispatch("stepChanged", { detail: { step: this.currentValue } })
  }

  // UI Update Methods
  #showCurrent() {
    this.#updateVisibility()
    this.#updateProgress()
    this.#updateURL()
    this.#updatePreviousButton()
  }

  #updatePreviousButton() {
    if (this.hasPreviousButtonTarget) {
      this.previousButtonTarget.disabled = this.currentValue <= 1
    }
  }

  #updateVisibility() {
    this.contentTargets.forEach(element => {
      const stepIndex = parseInt(element.dataset.stepsIndex)
      element.classList.toggle(this.hiddenClass, stepIndex !== this.currentValue)
    })
  }

  #updateProgress() {
    if (this.hasIndicatorTarget) {
      this.indicatorTargets.forEach((indicator, index) => {
        const isCurrent = index + 1 === this.currentValue
        const isDone = index + 1 < this.currentValue
        indicator.toggleAttribute('open', isCurrent)
        indicator.toggleAttribute('done', isDone)
      })
    }

    if (this.hasProgressTarget) {
      this.progressTarget.value = this.currentValue
    }

    if (this.hasCounterCurrentTarget) {
      this.counterCurrentTarget.textContent = this.currentValue
    }
  }

  #updateURL() {
    const url = new URL(window.location)
    url.searchParams.set('step', this.currentValue)
    window.history.pushState({}, '', url)
  }
}

