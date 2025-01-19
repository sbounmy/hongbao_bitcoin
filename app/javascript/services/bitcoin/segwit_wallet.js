import Master from 'services/bitcoin/master'
import * as bitcoin from 'bitcoinjs-lib'

export default class SegWitWallet extends Master {
  static PURPOSE = "84'"  // Just define the PURPOSE

  get payment() {
    return (publicKey, network) => bitcoin.payments.p2wpkh({ pubkey: publicKey, network })
  }

  static isValidAddress(address) {
    return address.startsWith('bc1') || address.startsWith('tb1')
  }
}