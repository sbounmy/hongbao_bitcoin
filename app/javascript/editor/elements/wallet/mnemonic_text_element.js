import { WalletTextElement } from "./text_element"

// Mnemonic text element - displays mnemonic phrase from wallet data
export class MnemonicTextElement extends WalletTextElement {
  static drawer = 'keys-drawer'
  static dataKey = 'mnemonic_text'
}
