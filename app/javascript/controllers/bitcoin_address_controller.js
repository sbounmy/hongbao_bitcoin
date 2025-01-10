import BitcoinKeyController from "controllers/bitcoin_key_controller"
import * as bitcoin from 'bitcoinjs-lib'

export default class extends BitcoinKeyController {
  _validate(address) {
    if (!address) throw new Error("Address is required")

      // Try bech32 (native segwit)
      if (address.startsWith('bc1') || address.startsWith('tb1')) {
        bitcoin.address.fromBech32(address)
      }
      // Try legacy or nested segwit
      else {
        bitcoin.address.fromBase58Check(address)
      }

      // Verify network
    //   const addressInfo = bitcoin.address.fromString(address)
    //   if (this.networkValue === 'testnet' && !address.startsWith('tb1') && !address.startsWith('m') && !address.startsWith('n') && !address.startsWith('2')) {
    //     throw new Error('Invalid testnet address')
    //   }
    //   if (this.networkValue === 'mainnet' && !address.startsWith('bc1') && !address.startsWith('1') && !address.startsWith('3')) {
    //     throw new Error('Invalid mainnet address')
    //   }
  }
}