import { BaseElement } from "./base_element"
import { TextElement } from "./text_element"
import { ImageElement } from "./image_element"

// Wallet elements
import { WalletTextElement } from "./wallet/text_element"
import { WalletQRElement } from "./wallet/qr_element"
import { PrivateKeyTextElement } from "./wallet/private_key_text_element"
import { PublicAddressTextElement } from "./wallet/public_address_text_element"
import { MnemonicTextElement } from "./wallet/mnemonic_text_element"
import { PrivateKeyQRElement } from "./wallet/private_key_qr_element"
import { PublicAddressQRElement } from "./wallet/public_address_qr_element"

// Element type registry
// Maps type strings to element classes
const ELEMENT_TYPES = {
  // User elements
  'text': TextElement,
  'image': ImageElement,

  // Wallet text elements
  'private_key/text': PrivateKeyTextElement,
  'public_address/text': PublicAddressTextElement,
  'mnemonic/text': MnemonicTextElement,

  // Wallet QR elements
  'private_key/qrcode': PrivateKeyQRElement,
  'public_address/qrcode': PublicAddressQRElement,
}

// Factory function to create element instances
export function createElement(data) {
  const type = data.type || 'text'
  const ElementClass = ELEMENT_TYPES[type] || TextElement

  return new ElementClass(data)
}

// Register a new element type
export function registerElementType(type, ElementClass) {
  ELEMENT_TYPES[type] = ElementClass
}

// Get all registered types
export function getRegisteredTypes() {
  return Object.keys(ELEMENT_TYPES)
}

// Export element classes for direct use
export {
  BaseElement,
  TextElement,
  ImageElement,
  WalletTextElement,
  WalletQRElement,
  PrivateKeyTextElement,
  PublicAddressTextElement,
  MnemonicTextElement,
  PrivateKeyQRElement,
  PublicAddressQRElement
}
