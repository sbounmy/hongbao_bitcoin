import * as bitcoin from 'bitcoinjs-lib'
import { BIP32Factory } from 'bip32'
import * as ecc from 'tiny-secp256k1'
import { mnemonicToSeedSync, generateMnemonic } from 'bip39'

export class BitcoinWallet {
  static generate() {
    const mnemonic = generateMnemonic()
    const seed = mnemonicToSeedSync(mnemonic)
    const bip32 = BIP32Factory(ecc)
    const root = bip32.fromSeed(seed)
    const child = root.derivePath("m/84'/0'/0'/0/0")

    const { address } = bitcoin.payments.p2wpkh({
      pubkey: child.publicKey,
      network: bitcoin.networks.bitcoin
    })

    return {
      mnemonic,
      address,
      privateKey: child.privateKey.toString('hex')
    }
  }
}