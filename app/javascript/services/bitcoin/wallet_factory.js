import LegacyWallet from './legacy_wallet'
import SegWitWallet from './segwit_wallet'
// Factory to create appropriate wallet type
export default class WalletFactory {
  static createFromAddress(address, options = {}) {
    if (LegacyWallet.isValidAddress(address)) {
      return new LegacyWallet(options)
    }
    return new SegWitWallet(options)
  }

  static createDefault(options = {}) {
    return new SegWitWallet(options)  // Default to SegWit
  }
}