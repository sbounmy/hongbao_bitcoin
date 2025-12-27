import { WalletTextElement } from "./text_element"

// Public address text element - displays public address from wallet data
export class PublicAddressTextElement extends WalletTextElement {
  static drawer = 'style-drawer'
  static dataKey = 'public_address_text'
}
