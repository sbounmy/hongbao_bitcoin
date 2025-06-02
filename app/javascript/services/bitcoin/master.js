import Wallet from './wallet'
import { BIP32Factory } from 'bip32'
import secp256k1 from '@bitcoinerlab/secp256k1'
import * as bip39 from '../../../../vendor/javascript/bip39.js'
// import bitcoin from 'bitcoinjs-lib'
import * as bitcoin from '../../../../vendor/javascript/bitcoinjs-lib.js'
export default class Master extends Wallet {
  static COIN_TYPE = {
    MAINNET: "0'",
    TESTNET: "1'"
  }

  // Rename to make it clearer this is the prefix
  get derivationPrefix() {
    if (!this.constructor.PURPOSE) {
      throw new Error('PURPOSE must be defined in derived wallet class')
    }
    return `m/${this.constructor.PURPOSE}/${this.coinType}/0'/0/`
  }

  get coinType() {
    return this.network === bitcoin.networks.testnet ?
      Master.COIN_TYPE.TESTNET :
      Master.COIN_TYPE.MAINNET
  }

  constructor(options = {}) {
    super(options)
    this.bip32 = BIP32Factory(secp256k1)

    console.log("constructor", options)
    if (options.mnemonic) {
      this.initializeFromMnemonic(options.mnemonic)
    } else if (options.seed) {
      this.initializeFromSeed(options.seed)
    } else if (options.publicAddress) {
      this.initializeFromPublicAddress(options.publicAddress)
    } else if (!options.wallet && !options.privateKey) {
      this.generate()
    }
  }

  static generate() {
    return new Master()
  }

  get mtPelerin() {
    return true
  }

  generate() {
    this.mnemonic = bip39.generateMnemonic(256)
    this.initializeFromMnemonic(this.mnemonic)
  }

  initializeFromMnemonic(mnemonic) {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw new Error('Invalid mnemonic')
    }
    this.mnemonic = mnemonic
    this.seed = bip39.mnemonicToSeedSync(mnemonic)
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

  initializeFromPublicAddress(publicAddress) {
    if (typeof publicAddress === 'string') {
      publicAddress = Buffer.from(publicAddress, 'hex')
    }
    console.log("initializeFromPublicAddress", publicAddress)
    this.wallet = this.bip32.fromPublicKey(publicAddress, this.network)
    super.initializeFromWallet(this.wallet)
  }

  derive(path = '0') {
    if (!this.wallet) throw new Error('HD node not initialized')
    const fullPath = `${this.derivationPrefix}${path}`
    const childWallet = this.wallet.derivePath(fullPath)

    return new this.constructor({
      wallet: childWallet,
      network: this.networkString
    })
  }

  get networkString() {
    return this.network === bitcoin.networks.bitcoin ? 'mainnet' : 'testnet'
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