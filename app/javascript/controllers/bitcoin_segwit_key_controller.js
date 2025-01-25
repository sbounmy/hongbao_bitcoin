import BitcoinWifController from "controllers/bitcoin_wif_controller"
import * as bitcoin from 'bitcoinjs-lib'

export default class extends BitcoinWifController {
  deriveAddress(keyPair) {
    const { address } = bitcoin.payments.p2wpkh({
      pubkey: keyPair.publicKey,
      network: this.network
    })
    return address
  }

  static isValidAddress(address) {
    return address.startsWith('bc1') ||
           address.startsWith('tb1')
  }
}