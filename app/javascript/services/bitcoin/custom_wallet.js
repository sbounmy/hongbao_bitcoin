import Master from './/master'
import * as bitcoin from '../../../../vendor/javascript/bitcoinjs-lib.js'

export default class CustomWallet extends Master {

  get mtPelerin() {
    return false
  }

  initializeFromPublicAddress(publicAddress) {
    this.publicAddress = publicAddress
  }

  initializeFromPrivateKey(privateKey) {
    this.privateKey = privateKey
  }

  initializeFromMnemonic(mnemonic) {
    this.mnemonic = mnemonic
  }

  update(options) {
    Object.assign(this, options)
    return this
  }

  derive(path = '0') {
    return this
  }

  payment(publicKey, network) {
    return {
      address: this.publicAddress || '',
      path: this.path
    }
  }

  get wif() {
    return this.privateKey || ''
  }

  static isValidAddress(address) {
    return true
  }
}