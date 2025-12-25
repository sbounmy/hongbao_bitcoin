import { BaseElement } from "./base_element"
import { TextElement } from "./text_element"
import { TransientTextElement } from "./transient_text_element"
import { QRElement } from "./qr_element"
import { PortraitElement } from "./portrait_element"

// Element type registry
// Maps type strings to element classes
const ELEMENT_TYPES = {
  // Custom user text
  'text': TextElement,

  // Transient text (content set externally)
  'mnemonic/text': TransientTextElement,
  'private_key/text': TransientTextElement,
  'public_address/text': TransientTextElement,

  // QR codes
  'qrcode': QRElement,
  'private_key/qrcode': QRElement,
  'public_address/qrcode': QRElement,

  // Portrait/image
  'portrait': PortraitElement,
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
  TransientTextElement,
  QRElement,
  PortraitElement
}
