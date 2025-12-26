import { WalletTextElement } from "./text_element"

// Private key text element - displays private key from wallet data
export class PrivateKeyTextElement extends WalletTextElement {
  static drawer = 'keys-drawer'
  static dataKey = 'private_key_text'
}
