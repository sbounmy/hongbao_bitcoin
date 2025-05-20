import BitcoinKeyController from "./bitcoin_key_controller"
import * as secp256k1 from 'secp256k1'
import { ECPairFactory } from 'ecpair'
import { BIP32Factory } from 'bip32'

// Base controller for WIF validation
export default class extends BitcoinKeyController {
  static targets = ["errorMessage"]
  static values = {
    network: String,
    address: String
  }

  validate(event) {
    const validationResult = this._validate(event.target.value)
    this.updateErrorMessage(validationResult.error)

    if (validationResult.isValid) {
      this.dispatch('valid')
    } else {
      this.dispatch('invalid')
    }

    return validationResult.isValid
  }

  _validate(wif) {
    try {
      this.bip32 = BIP32Factory(secp256k1)
      const ECPair = ECPairFactory(secp256k1)
      const ecPair = ECPair.fromWIF(wif, this.network)
      const keyPair = this.bip32.fromPrivateKey(Buffer.from(ecPair.privateKey), Buffer.alloc(32))
      const derivedAddress = this.deriveAddress(keyPair)

      if (derivedAddress !== this.addressValue) {
        return {
          isValid: false,
          error: "This private key does not match the address"
        }
      }

      return {
        isValid: true,
        error: null
      }
    }
     catch (e) {
      console.error(e)
      return {
        isValid: false,
        error: "Invalid private key format"
      }
    }
  }

  // To be implemented by child classes
  deriveAddress(keyPair) {
    throw new Error("Must be implemented by child class")
  }

  updateErrorMessage(message) {
    if (message) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove('hidden')
    } else {
      this.errorMessageTarget.classList.add('hidden')
    }
  }
}