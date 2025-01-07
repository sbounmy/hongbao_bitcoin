import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "indicator"]
  static classes = ["hidden"]
  static values = {
    current: Number
  }

  connect() {
    this.#showCurrent()
  }

  next(event) {
    this.currentValue++
  }

  previous(event) {
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
  }

  #updateVisibility() {
    this.contentTargets.forEach((step, index) => {
      step.classList.toggle('hidden', index + 1 !== this.currentValue)
    })
  }

  #updateProgress() {
    this.indicatorTargets.forEach((indicator, index) => {
      const isCurrent = index + 1 === this.currentValue
      const isDone = index + 1 < this.currentValue
      indicator.toggleAttribute('open', isCurrent)
      indicator.toggleAttribute('done', isDone)
    })
  }

  #updateURL() {
    const url = new URL(window.location)
    url.searchParams.set('step', this.currentValue)
    window.history.pushState({}, '', url)
  }
}

