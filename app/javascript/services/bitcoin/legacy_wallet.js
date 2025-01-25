import Master from 'services/bitcoin/master'
import * as bitcoin from 'bitcoinjs-lib'

export default class LegacyWallet extends Master {
  static PURPOSE = "44'"  // Just define the PURPOSE

  get payment() {
    return (publicKey, network) => bitcoin.payments.p2pkh({ pubkey: publicKey, network })
  }

  static isValidAddress(address) {
    return address.startsWith('1') ||
           address.startsWith('m') ||
           address.startsWith('n')
  }
}