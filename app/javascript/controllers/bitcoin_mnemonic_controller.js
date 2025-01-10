import BitcoinKeyController from "controllers/bitcoin_key_controller"
import 'bip39'

export default class extends BitcoinKeyController {
  static outlets = ["word"]

  connect() {
    this.validWords = bip39.wordlists.english
  }

  fill(event) {
    const { startIndex, words } = event.detail
    const outlets = this.wordOutlets

    words.forEach((word, index) => {
      const targetIndex = startIndex + index
      const outlet = this.wordOutlets[targetIndex]
      if (!outlet) return
      outlet.inputTarget.value = word
      outlet.validateWord()
    })

    // Focus the next empty input after filling
    const nextEmptyOutlet = this.wordOutlets.find(outlet => !outlet.inputTarget.value.trim())
    if (nextEmptyOutlet) {
      nextEmptyOutlet.inputTarget.focus()
    }
  }

  _validate(mnemonic) {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw new Error("Invalid mnemonic phrase")
    }
  }

  // Method called by word outlets to validate individual words
  validateWord(word) {
    if (!word) return null
    return this.validWords.includes(word.toLowerCase().trim())
  }

  // Get all words for full validation
  get phrase() {
    return this.wordOutlets
      .map(outlet => outlet.word)
      .filter(Boolean)
      .join(" ")
  }
}