import Wallet from 'services/bitcoin/wallet'
import { BIP32Factory } from 'bip32'
import * as secp256k1 from 'secp256k1'
import 'bip39'
import bitcoin from 'bitcoinjs-lib'

export default class Master extends Wallet {
  static PATHS = {
    LEGACY: {
      path: "m/44'/0'/0'/0/0",
      payment: (publicKey, network) => bitcoin.payments.p2pkh({ pubkey: publicKey, network })
    },
    SEGWIT: {
      path: "m/84'/0'/0'/0/0",
      payment: (publicKey, network) => bitcoin.payments.p2wpkh({ pubkey: publicKey, network })
    }
  }

  constructor(options = {}) {
    super(options)
    this.bip32 = BIP32Factory(secp256k1)

    if (options.mnemonic) {
      this.initializeFromMnemonic(options.mnemonic)
    } else if (options.seed) {
      this.initializeFromSeed(options.seed)
    } else if (!options.wallet && !options.privateKey) {
      this.generate()
    }
  }

  static generate() {
    return new Master()
  }

  generate() {
    this.mnemonic = window.bip39.generateMnemonic(256)
    this.initializeFromMnemonic(this.mnemonic)
  }

  initializeFromMnemonic(mnemonic) {
    if (!window.bip39.validateMnemonic(mnemonic)) {
      throw new Error('Invalid mnemonic')
    }
    this.mnemonic = mnemonic
    this.seed = window.bip39.mnemonicToSeedSync(mnemonic)
    this.wallet = this.bip32.fromSeed(this.seed, this.network)
    super.initializeFromWallet(this.wallet)
  }

  initializeFromSeed(seed) {
    if (typeof seed === 'string') {
      seed = Buffer.from(seed, 'hex')
    }
    this.seed = seed
    this.wallet = this.bip32.fromSeed(this.seed, this.network)
    super.initializeFromWallet(this.wallet)
  }

  deriveForAddress(address) {
    const scheme = address.startsWith('1') ? Master.PATHS.LEGACY : Master.PATHS.SEGWIT
    const wallet = this.derive(scheme.path)
    wallet.payment = scheme.payment
    return wallet
  }

  derive(path) {
    if (!this.wallet) throw new Error('HD node not initialized')
    const childWallet = this.wallet.derivePath(path)
    return new Wallet({
      wallet: childWallet,
      network: this.network
    })
  }

  dispatchWalletEvent(eventName, detail = {}) {
    const event = new CustomEvent(`wallet:${eventName}`, {
      bubbles: true,
      detail: {
        ...detail,
        wallet: this,
        mnemonic: this.mnemonic
      }
    })
    window.dispatchEvent(event)
  }
}