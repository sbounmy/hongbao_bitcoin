import * as bitcoin from 'bitcoinjs-lib'
import { ECPairFactory } from 'ecpair'
import { initEccLib } from 'bitcoinjs-lib'
import * as secp256k1 from 'secp256k1'
import { Buffer } from 'buffer'
import QRCode from 'qrcode'

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

export default class Node {
  constructor(options = {}) {
    this.initializeDependencies()
    this.network = options.network || bitcoin.networks.bitcoin

    if (options.node) {
      this.initializeFromNode(options.node)
    } else if (options.privateKey) {
      this.initializeFromPrivateKey(options.privateKey)
    }
  }

  initializeDependencies() {
    if (typeof window !== 'undefined' && !window.Buffer) {
      window.Buffer = Buffer
    }
    this.ECPair = ECPairFactory(secp256k1)
  }

  initializeFromNode(node) {
    this.node = node
    this.privateKey = node.privateKey
    this.publicKey = node.publicKey
  }

  initializeFromPrivateKey(privateKey) {
    this.keyPair = this.ECPair.fromWIF(privateKey, this.network)
  }

  set keyPair(keyPair) {
    this.keyPair = keyPair
    this.privateKey = keyPair.privateKey
    this.publicKey = keyPair.publicKey
  }

  get wif() {
    return this.ECPair.fromPrivateKey(this.privateKey).toWIF()
  }

  get address() {
    return bitcoin.payments.p2wpkh({
      pubkey: this.publicKey,
      network: this.network
    }).address
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
      address: this.address.toString('hex'),
      publicKey: this.publicKey,
      privateKey: this.wif,
      addressQrcode: async () => await QRCode.toDataURL(this.address.toString('hex')),
      publicKeyQrcode: async () => await QRCode.toDataURL(this.publicKey.toString('hex')),
      privateKeyQrcode: async () => await QRCode.toDataURL(this.wif)
    }
  }
}