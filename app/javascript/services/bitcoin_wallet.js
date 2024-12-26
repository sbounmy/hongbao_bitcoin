import * as bitcoin from 'bitcoinjs-lib'
import { ECPairFactory } from 'ecpair'
import { initEccLib } from 'bitcoinjs-lib'
import * as secp256k1 from '@bitcoinerlab/secp256k1'
import { Buffer } from 'buffer'
import 'bip39'
import { BIP32Factory } from 'bip32'
import { magicHash } from 'services/bitcoin_message'
import QRCode from 'qrcode'

export default class BitcoinWallet {
  static network = 'testnet'

  constructor(options = {}) {
    this.initializeDependencies()
    this.network = BitcoinWallet.network === 'testnet' ? bitcoin.networks.testnet : bitcoin.networks.bitcoin

    if (options.mnemonic) {
      this.initializeFromMnemonic(options.mnemonic)
    } else if (options.seed) {
      this.initializeFromSeed(options.seed)
    } else if (options.privateKey) {
      this.initializeFromPrivateKey(options.privateKey)
    }
  }

  initializeDependencies() {
    initEccLib(secp256k1)
    if (typeof window !== 'undefined' && !window.Buffer) {
      window.Buffer = Buffer
    }
    this.ECPair = ECPairFactory(secp256k1)
    this.bip32 = BIP32Factory(secp256k1)
  }

  initializeFromMnemonic(mnemonic) {
    if (!window.bip39.validateMnemonic(mnemonic)) {
      throw new Error('Invalid mnemonic')
    }
    this.mnemonic = mnemonic
    this.seed = window.bip39.mnemonicToSeedSync(mnemonic)
    this.root = this.bip32.fromSeed(this.seed, this.network)
    // Entropy can be recovered from mnemonic if needed
    this.entropy = window.bip39.mnemonicToEntropy(mnemonic)
  }

  initializeFromSeed(seed) {
    if (typeof seed === 'string') {
      seed = Buffer.from(seed, 'hex')
    }
    this.seed = seed
    this.root = this.bip32.fromSeed(this.seed, this.network)
    this.mnemonic = null
    this.entropy = null
  }

  initializeFromPrivateKey(privateKey) {
    const keyPair = this.ECPair.fromWIF(privateKey, this.network)
    this.root = this.bip32.fromPrivateKey(keyPair.privateKey, Buffer.alloc(32), this.network)
    this.mnemonic = null
    this.seed = null
    this.entropy = null
  }

  static setNetwork(network) {
    BitcoinWallet.network = network
  }

  static generate() {
    const entropy = window.crypto.getRandomValues(new Uint8Array(32))
    const mnemonic = window.bip39.generateMnemonic(256, null, window.bip39.wordlists.english)
    return new BitcoinWallet({ mnemonic })
  }

  nodePathFor(path) {
    if (!this.root) throw new Error('Wallet not initialized properly')

    const node = this.root.derivePath(path)
    const keyPair = this.ECPair.fromPrivateKey(node.privateKey, { network: this.network })

    return {
      publicKey: node.publicKey.toString('hex'),
      privateKey: keyPair.toWIF(),
      address: bitcoin.payments.p2pkh({
        pubkey: node.publicKey,
        network: this.network
      }).address,
      async addressQrcode() {
        return await QRCode.toDataURL(this.address)
      },
      async privateKeyQrcode() {
        return await QRCode.toDataURL(this.privateKey)
      },
      async publicKeyQrcode() {
        return await QRCode.toDataURL(this.publicKey)
      }
    }
  }

  async generateMtPelerinRequest() {
    const key = this.nodePathFor("m/44'/0'/0'/0/0")
    const requestCode = Math.floor(1000 + Math.random() * 9000).toString()
    const message = `MtPelerin-${requestCode}`

    const keyPair = this.ECPair.fromWIF(key.privateKey, this.network)
    const messagePrefix = this.network === bitcoin.networks.testnet ? 'testnet' : 'bitcoin'
    const messageHash = magicHash(message, messagePrefix)
    const signature = keyPair.sign(messageHash)

    return {
      requestCode,
      requestHash: Buffer.from(signature).toString('base64')
    }
  }
}

window.BitcoinWallet = BitcoinWallet