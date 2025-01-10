import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = ["bitcoin-mnemonic"]
  static targets = ["input", "validIcon", "errorIcon"]
  static classes = ["valid", "invalid"]

  validateWord() {
    const word = this.inputTarget.value.trim()
    this.#removeStateClasses()
    this.#hideIcons()

    if (!word) return

    const isValid = this.bitcoinMnemonicOutlet.validateWord(word)
    this.#toggleValidationState(isValid)
    this.#showIcon(isValid)
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