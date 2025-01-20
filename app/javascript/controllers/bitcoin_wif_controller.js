import BitcoinKeyController from "controllers/bitcoin_key_controller"
import * as secp256k1 from 'secp256k1'
import { ECPairFactory } from 'ecpair'
import * as bitcoin from 'bitcoinjs-lib'

export default class extends BitcoinKeyController {
  validate(event) {
    console.log("validate", event.target.value)
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
      const ECPair = ECPairFactory(secp256k1)
      ECPair.fromWIF(wif, this.network)
      return {
        isValid: true,
        error: null
      }
    } catch (e) {
      return {
        isValid: false,
        error: e.message
      }
    }
  }
}