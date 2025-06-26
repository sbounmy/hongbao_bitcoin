import BitcoinWifController from "./bitcoin_wif_controller"
import bitcoin from '../../../../vendor/javascript/bitcoinjs-lib.js'

export default class extends BitcoinWifController {
  deriveAddress(keyPair) {
    const { address } = bitcoin.payments.p2pkh({
      pubkey: keyPair.publicKey,
      network: this.network
    })
    return address
  }

  static isValidAddress(address) {
    return address.startsWith('1') ||
           address.startsWith('m') ||
           address.startsWith('n')
  }
}