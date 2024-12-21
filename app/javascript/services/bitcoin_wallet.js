import * as bitcoin from 'bitcoinjs-lib'
import { ECPairFactory } from 'ecpair'
import { initEccLib } from 'bitcoinjs-lib'
import * as secp256k1 from '@bitcoinerlab/secp256k1'
import { Buffer } from 'buffer'
import 'bip39'
import { BIP32Factory } from 'bip32'
import { magicHash } from 'services/bitcoin_message'

export default class BitcoinWallet {
  constructor(networkType = 'testnet') {
    this.initializeDependencies()
    this.network = networkType === 'testnet' ? bitcoin.networks.testnet : bitcoin.networks.bitcoin
    this.currentKeyPair = null
  }

  initializeDependencies() {
    initEccLib(secp256k1)
    if (typeof window !== 'undefined' && !window.Buffer) {
      window.Buffer = Buffer
    }
    this.ECPair = ECPairFactory(secp256k1)
    this.bip32 = BIP32Factory(secp256k1)
  }

  async generateKeyPair() {
    const mnemonic = window.bip39.generateMnemonic(256)
    const seed = window.bip39.mnemonicToSeedSync(mnemonic)
    const root = this.bip32.fromSeed(seed)

    const path = this.network === bitcoin.networks.testnet ?
      "m/44'/1'/0'/0/0" : "m/44'/0'/0'/0/0"
    const child = root.derivePath(path)

    const keyPair = this.ECPair.fromPrivateKey(child.privateKey, { network: this.network })

    this.currentKeyPair = {
      privateKeyWIF: keyPair.toWIF(),
      address: bitcoin.payments.p2pkh({
        pubkey: Buffer.from(child.publicKey),
        network: this.network
      }).address,
      mnemonic: mnemonic
    }

    return this.currentKeyPair
  }

  async generateMtPelerinRequest() {
    if (!this.currentKeyPair) {
      throw new Error('No key pair generated yet. Call generateKeyPair first.')
    }

    const requestCode = Math.floor(1000 + Math.random() * 9000).toString()
    const message = `MtPelerin-${requestCode}`

    const keyPair = this.ECPair.fromWIF(this.currentKeyPair.privateKeyWIF, this.network)

    const messagePrefix = this.network === bitcoin.networks.testnet ? 'testnet' : 'bitcoin'
    const messageHash = magicHash(message, messagePrefix)
    const signature = keyPair.sign(messageHash)

    const signatureBuffer = Buffer.from(signature)
    const signatureBase64 = signatureBuffer.toString('base64')

    return {
      requestCode,
      requestHash: signatureBase64
    }
  }

  getCheckmarkIcon() {
    return `
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
      </svg>
    `
  }

  getCopyIcon() {
    return `
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
      </svg>
    `
  }
}