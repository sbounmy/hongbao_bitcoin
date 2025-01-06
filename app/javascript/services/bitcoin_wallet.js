import * as bitcoin from 'bitcoinjs-lib'
import { ECPairFactory } from 'ecpair'
import { initEccLib } from 'bitcoinjs-lib'
import * as secp256k1 from 'secp256k1'
import { Buffer } from 'buffer'
import 'bip39'
import { BIP32Factory } from 'bip32'
import QRCode from 'qrcode'
import { randomBytes } from '@noble/hashes/utils'

// Initialize secp256k1 before importing bitcoinjs-message
initEccLib(secp256k1)
import bitcoinMessage from 'bitcoinjs-message'

// DIRTYFIX Override the sign function with access to the internal functions
function prepareSign(messagePrefixArg, sigOptions) {
  if (typeof messagePrefixArg === 'object' && sigOptions === undefined) {
    sigOptions = messagePrefixArg
    messagePrefixArg = undefined
  }
  let { segwitType, extraEntropy } = sigOptions || {}
  if (segwitType && (typeof segwitType === 'string' || segwitType instanceof String)) {
    segwitType = segwitType.toLowerCase()
  }
  if (segwitType && segwitType !== 'p2sh(p2wpkh)' && segwitType !== 'p2wpkh') {
    throw new Error('Unrecognized segwitType: use "p2sh(p2wpkh)" or "p2wpkh"')
  }
  return { messagePrefixArg, segwitType, extraEntropy }
}

function isSigner(obj) {
  return obj && typeof obj.sign === 'function'
}

function encodeSignature(signature, recovery, compressed, segwitType) {
  if (segwitType !== undefined) {
    recovery += 8
    if (segwitType === 'p2wpkh') recovery += 4
  } else {
    if (compressed) recovery += 4
  }
  return Buffer.concat([Buffer.alloc(1, recovery + 27), signature])
}

// Override the sign function with access to the internal functions
bitcoinMessage.sign = function sign(
  message,
  privateKey,
  compressed,
  messagePrefix,
  sigOptions
) {
  const {
    messagePrefixArg,
    segwitType,
    extraEntropy
  } = prepareSign(messagePrefix, sigOptions)
  const hash = bitcoinMessage.magicHash(message, messagePrefixArg)
  const sigObj = isSigner(privateKey)
    ? privateKey.sign(hash, extraEntropy)
    : secp256k1.signRecoverable(hash, privateKey, extraEntropy)
  return encodeSignature(
    sigObj.signature,
    sigObj.recoveryId,
    compressed,
    segwitType
  )
}.bind(bitcoinMessage)
// DIRTYFIX END

export default class BitcoinWallet {
  static network = 'mainnet'

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

  sign(message) {
    if (!this.root) throw new Error('Wallet not initialized properly')

    const keyPair = this.ECPair.fromWIF(this.nodePathFor("m/44'/0'/0'/0/0").privateKey, this.network)

    // Convert message to Buffer
    const messageBuffer = Buffer.from(message)
    const privateKeyBuffer = keyPair.privateKey

    try {
      const signature = bitcoinMessage.sign(
        messageBuffer,
        privateKeyBuffer,
        keyPair.compressed
        //{ extraEntropy: randomBytes(32) }  // Pass extraEntropy as an options object with 'data' key
      )
      return signature.toString('base64')
    } catch (error) {
      console.error('Signing error:', error)
      throw error
    }
  }

  verify(message, signature, address) {
    try {
      return bitcoinMessage.verify(
        message,
        address,
        Buffer.from(signature, 'base64')
      )
    } catch (error) {
      console.error('Signature verification failed:', error)
      return false
    }
  }

}

// Initialize global wallet immediately
window.wallet = BitcoinWallet.generate()