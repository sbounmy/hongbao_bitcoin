import BitcoinKeyController from "./bitcoin_key_controller"
import * as bitcoin from '../../../../vendor/javascript/bitcoinjs-lib.js'

export default class extends BitcoinKeyController {
  static values = {
    network: String
  }

  _validate(address) {
    if (!address) throw new Error("Address is required")

    try {
      // Try bech32 (native segwit)
      if (address.startsWith('bc1') || address.startsWith('tb1')) {
        bitcoin.address.fromBech32(address)
      }
      // Try legacy or nested segwit
      else {
        bitcoin.address.fromBase58Check(address)
      }

      // Verify network
      if (this.networkValue === 'testnet' && !address.startsWith('tb1') && !address.startsWith('m') && !address.startsWith('n') && !address.startsWith('2')) {
        throw new Error('Invalid testnet address')
      }
      if (this.networkValue === 'mainnet' && !address.startsWith('bc1') && !address.startsWith('1') && !address.startsWith('3')) {
        throw new Error('Invalid mainnet address')
      }
    } catch (e) {
      throw new Error(e.message)
    }
  }
}