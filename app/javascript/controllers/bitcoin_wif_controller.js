import BitcoinKeyController from "controllers/bitcoin_key_controller"
import ECPairFactory from 'ecpair'
import * as bitcoin from 'bitcoinjs-lib'

export default class extends BitcoinKeyController {
  _validate(wif) {
    try {
      const ECPair = ECPairFactory.ECPairFactory(bitcoin.networks.bitcoin)
      ECPair.fromWIF(wif, this._network)
    } catch (e) {
      throw new Error("Invalid WIF format")
    }
  }
}