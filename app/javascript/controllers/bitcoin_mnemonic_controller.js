import BitcoinKeyController from "controllers/bitcoin_key_controller"
import * as bip39 from 'bip39'

export default class extends BitcoinKeyController {
  _validate(mnemonic) {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw new Error("Invalid mnemonic phrase")
    }
  }
}