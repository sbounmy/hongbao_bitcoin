import * as bitcoin from '../../../../vendor/javascript/bitcoinjs-lib.js'
import { ECPairFactory } from 'ecpair'
import secp256k1 from '@bitcoinerlab/secp256k1'
import { Buffer } from 'buffer'
import QRCode from 'qrcode'
import { BIP32Factory } from 'bip32'

// Initialize secp256k1 before importing bitcoinjs-message
bitcoin.initEccLib(secp256k1)
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

export default class Wallet {
  constructor(options = {}) {
    this.initializeDependencies()
    this.network = options.network == 'mainnet' ? bitcoin.networks.bitcoin : bitcoin.networks.testnet

    if (options.wallet) {
      this.initializeFromWallet(options.wallet)
    } else if (options.privateKey) {
      this.initializeFromPrivateKey(options.privateKey)
    }
  }

  initializeDependencies() {
    this.ECPair = ECPairFactory(secp256k1)
    this.bip32 = BIP32Factory(secp256k1)
  }

  initializeFromWallet(wallet) {
    this.wallet = wallet
    this.privateKey = wallet.privateKey
    this.publicKey = wallet.publicKey
  }

  initializeFromPrivateKey(privateKey) {
    const ecPair = this.ECPair.fromWIF(privateKey, this.network)
    this.keyPair = this.bip32.fromPrivateKey(Buffer.from(ecPair.privateKey), Buffer.alloc(32))
    this.privateKey = this.keyPair.privateKey
    this.publicKey = this.keyPair.publicKey
  }

  get wif() {
    return this.ECPair.fromPrivateKey(this.privateKey, { network: this.network }).toWIF()
  }

  get address() {
    if (!this.payment) {
      throw new Error('Payment method must be defined in derived wallet class')
    }

    return this.payment(this.publicKey, this.network).address
  }

  sign(message) {
    if (!this.privateKey) throw new Error('Private key required for signing')

    const messageBuffer = Buffer.from(message)
    const signature = bitcoinMessage.sign(
      messageBuffer,
      this.privateKey,
      true // compressed
    )
    return signature.toString('base64')
  }

  verify(message, signature, address) {
    try {
      return bitcoinMessage.verify(
        message,
        address || this.address,
        Buffer.from(signature, 'base64')
      )
    } catch (error) {
      console.error('Signature verification failed:', error)
      return false
    }
  }

  get info() {
    return {
      publicAddressText: this.address,
      publicKeyText: this.publicKey,
      privateKeyText: this.wif,
      publicAddressQrcode: async () => await this.#qrcode(this.address),
      appPublicAddressQrcode: async () => await this.#qrcode(this.appPublicAddress),
      publicKeyQrcode: async () => await this.#qrcode(this.publicKey),
      privateKeyQrcode: async () => await this.#qrcode(this.wif)
    }
  }

  get appPublicAddress() {
    return window.location.origin + "/addrs/" + this.address
  }

  #qrcode(data) {
    if (!data) return null
    return QRCode.toDataURL(data, { type: 'image/webp', margin: 1.5 })
  }
}