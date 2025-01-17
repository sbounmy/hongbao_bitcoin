import Node from 'services/bitcoin/node'
import { BIP32Factory } from 'bip32'
import * as secp256k1 from 'secp256k1'
import 'bip39'

export default class Master extends Node {
  constructor(options = {}) {
    super(options)
    this.bip32 = BIP32Factory(secp256k1)

    if (options.mnemonic) {
      this.initializeFromMnemonic(options.mnemonic)
    } else if (options.seed) {
      this.initializeFromSeed(options.seed)
    } else if (!options.node && !options.privateKey) {
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
    this.node = this.bip32.fromSeed(this.seed, this.network)
    super.initializeFromNode(this.node)
  }

  initializeFromSeed(seed) {
    if (typeof seed === 'string') {
      seed = Buffer.from(seed, 'hex')
    }
    this.seed = seed
    this.node = this.bip32.fromSeed(this.seed, this.network)
    super.initializeFromNode(this.node)
  }

  derive(path) {
    if (!this.node) throw new Error('HD node not initialized')
    const childNode = this.node.derivePath(path)
    return new Node({
      node: childNode,
      network: this.network
    })
  }

  // Extended key methods
  toExtendedPublic() {
    return this.node.neutered().toBase58()
  }

  toExtendedPrivate() {
    if (!this.node.privateKey) throw new Error('No private key available')
    return this.node.toBase58()
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

  static getDerivationPath(address) {
    // For legacy addresses (starting with 1)
    if (address.startsWith("1")) {
      return "m/44'/0'/0'/0/0"
    }
    // For native segwit addresses (starting with bc1)
    return "m/84'/0'/0'/0/0"
  }

  deriveForAddress(address) {
    const path = Master.getDerivationPath(address)
    return this.derive(path)
  }
}