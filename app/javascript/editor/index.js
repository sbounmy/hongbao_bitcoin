import { BaseElement } from './elements/base_element'
import {
  TextElement,
  WalletTextElement,
  PrivateKeyTextElement,
  PublicAddressTextElement,
  MnemonicTextElement
} from './elements/text_element'
import { ImageElement } from './elements/image_element'
import {
  QRElement,
  PrivateKeyQRElement,
  PublicAddressQRElement
} from './elements/qr_element'
import { Engine } from './engine'
import { Exporter } from './exporter'
import { Canvas } from './canvas'
import { CanvasPair } from './canvas_pair'
import { Selection } from './selection'
import { State } from './state'
import { TouchHandler } from './touch_handler'

// Element type registry - maps type strings to element classes
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
  WalletTextElement,
  PrivateKeyTextElement,
  PublicAddressTextElement,
  MnemonicTextElement,
  ImageElement,
  QRElement,
  PrivateKeyQRElement,
  PublicAddressQRElement,
  // Core engine classes
  Engine,
  Exporter,
  Canvas,
  CanvasPair,
  Selection,
  State,
  TouchHandler
}
