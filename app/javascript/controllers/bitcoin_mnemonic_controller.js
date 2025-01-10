import BitcoinKeyController from "controllers/bitcoin_key_controller"
import 'bip39'

export default class extends BitcoinKeyController {
  static outlets = ["mnemonic-word"]

  connect() {
    this.validWords = bip39.wordlists.english
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
    return this.mnemonicWordOutlets
      .map(outlet => outlet.word)
      .filter(Boolean)
      .join(" ")
  }
}