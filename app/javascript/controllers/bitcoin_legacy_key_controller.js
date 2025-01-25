import BitcoinWifController from "controllers/bitcoin_wif_controller"
import * as bitcoin from 'bitcoinjs-lib'

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