import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = ["bitcoin-mnemonic"]
  static targets = ["input", "validIcon", "errorIcon"]
  static classes = ["valid", "invalid"]

  get word() {
    return this.inputTarget.value.trim()
  }

  validateWord() {
    const word = this.word
    this.#removeStateClasses()
    this.#hideIcons()

    if (!word) return

    const isValid = this.bitcoinMnemonicOutlet.validateWord(word)
    this.#toggleValidationState(isValid)
    this.#showIcon(isValid)
    this.bitcoinMnemonicOutlet.validate()
  }

  fill(event) {
    console.log("fill")
    event.preventDefault()
    const pastedText = event.clipboardData.getData('text')
    const words = pastedText.trim().split(/\s+/)

    // Multiple words: dispatch to parent for filling multiple inputs
    this.dispatch("fill", {
      detail: {
        startIndex: parseInt(this.inputTarget.getAttribute('tabindex')),
        words: words
      }
    })
  }

  // Private methods
  #toggleValidationState(isValid) {
    if (isValid) {
      this.element.classList.add(...this.validClasses)
      this.element.classList.remove(...this.invalidClasses)
    } else {
      this.element.classList.add(...this.invalidClasses)
      this.element.classList.remove(...this.validClasses)
    }
  }

  #hideIcons() {
    this.validIconTarget.classList.add('hidden')
    this.errorIconTarget.classList.add('hidden')
  }

  #showIcon(isValid) {
    if (isValid) {
      this.validIconTarget.classList.remove('hidden')
    } else {
      this.errorIconTarget.classList.remove('hidden')
    }
  }

  #removeStateClasses() {
    this.element.classList.remove(...this.validClasses, ...this.invalidClasses)
  }
}