import BitcoinKeyController from "controllers/bitcoin_key_controller"
import BitcoinWallet from "services/bitcoin_wallet"
import 'bip39'

export default class extends BitcoinKeyController {
  static outlets = ["word"]
  static targets = ["errorMessage"]
  static values = {
    address: String
  }

  connect() {
    this.validWords = bip39.wordlists.english
  }

  deriveAddress(mnemonic, path) {
    try {
      const wallet = new BitcoinWallet({ mnemonic })
      const { address } = wallet.nodePathFor(path)
      return address
    } catch (error) {
      console.error('Error deriving address:', error)
      return null
    }
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

    this.validate()
  }

  validate() {
    const validationResult = this._validate()
    this.updateErrorMessage(validationResult.error)
    this.dispatch(validationResult.isValid ? 'valid' : 'invalid')
    return validationResult.isValid
  }

  _validate() {
    // Check if all words are valid
    if (!this.allWordsValid()) {
      return {
        isValid: false,
        error: "Some words are invalid. Please check highlighted words."
      }
    }

    // Check if we have all 24 words
    if (this.wordOutlets.filter(outlet => outlet.word).length !== 24) {
      return {
        isValid: false,
        error: "Please enter all 24 words."
      }
    }

    // Validate mnemonic checksum
    if (!bip39.validateMnemonic(this.phrase)) {
      return {
        isValid: false,
        error: "Invalid mnemonic checksum. Please check your words."
      }
    }

    // Validate if the derived address matches
    if (this.derivedAddress !== this.addressValue) {
      return {
        isValid: false,
        error: `This mnemonic does not correspond to the address ${this.addressValue}. Please use private key to verify if your bill was created before 2025.`
      }
    }

    return { isValid: true, error: null }
  }

  get derivedAddress() {
    // For legacy addresses (starting with 1)
    if (this.addressValue.startsWith("1")) {
      return this.deriveAddress(this.phrase, "m/44'/0'/0'/0/0")
    }
    // For native segwit addresses (starting with bc1)
    return this.deriveAddress(this.phrase, "m/84'/0'/0'/0/0")
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

  // Helper methods for error handling
  updateErrorMessage(message) {
    if (message) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove('hidden')
    } else {
      this.errorMessageTarget.classList.add('hidden')
    }
  }

  // Check if all entered words are valid
  allWordsValid() {
    return this.wordOutlets
      .filter(outlet => outlet.word) // Only check filled words
      .every(outlet => this.validateWord(outlet.word))
  }
}