import { BaseDOMElement } from './base_dom_element'
import {
  TextDOMElement,
  WalletTextDOMElement,
  PrivateKeyTextDOMElement,
  PublicAddressTextDOMElement,
  MnemonicTextDOMElement
} from './text_dom_element'
import { ImageDOMElement } from './image_dom_element'
import {
  QRDOMElement,
  PrivateKeyQRDOMElement,
  PublicAddressQRDOMElement
} from './qr_dom_element'
import { DOMEngine } from './dom_engine'
import { DOMExporter } from './dom_exporter'
import { DOMCanvas } from './dom_canvas'
import { DOMCanvasPair } from './dom_canvas_pair'
import { DOMSelection } from './dom_selection'

// Element type registry - maps type strings to DOM element classes
const ELEMENT_TYPES = {
  // User elements
  'text': TextDOMElement,
  'image': ImageDOMElement,

  // Wallet text elements
  'private_key/text': PrivateKeyTextDOMElement,
  'public_address/text': PublicAddressTextDOMElement,
  'mnemonic/text': MnemonicTextDOMElement,

  // Wallet QR elements
  'private_key/qrcode': PrivateKeyQRDOMElement,
  'public_address/qrcode': PublicAddressQRDOMElement,
}

// Factory function to create DOM element instances
export function createDOMElement(data) {
  const type = data.type || 'text'
  const ElementClass = ELEMENT_TYPES[type] || TextDOMElement

  return new ElementClass(data)
}

// Register a new element type
export function registerDOMElementType(type, ElementClass) {
  ELEMENT_TYPES[type] = ElementClass
}

// Get all registered types
export function getRegisteredDOMTypes() {
  return Object.keys(ELEMENT_TYPES)
}

// Export element classes for direct use
export {
  BaseDOMElement,
  TextDOMElement,
  WalletTextDOMElement,
  PrivateKeyTextDOMElement,
  PublicAddressTextDOMElement,
  MnemonicTextDOMElement,
  ImageDOMElement,
  QRDOMElement,
  PrivateKeyQRDOMElement,
  PublicAddressQRDOMElement,
  // Core engine classes
  DOMEngine,
  DOMExporter,
  DOMCanvas,
  DOMCanvasPair,
  DOMSelection
}
