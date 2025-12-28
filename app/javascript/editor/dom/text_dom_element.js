import { BaseDOMElement } from './base_dom_element'

// Text element rendered as DOM
// Uses CSS for fonts and text wrapping (better than canvas)
export class TextDOMElement extends BaseDOMElement {
  static SINGLE_LINE_THRESHOLD = 1.5

  constructor(data) {
    super(data)

    this.text = data.text || ''
    this.fontSize = parseFloat(data.font_size ?? data.fontSize ?? data.size) || 3
    this.fontColor = data.font_color || data.fontColor || data.color || '#000000'
  }

  renderContent() {
    // Create text span
    this.textNode = document.createElement('span')
    this.textNode.className = 'editor-element-text'
    this.el.appendChild(this.textNode)

    this.updateTextContent()
    this.applyTextStyles()
  }

  applyStyles() {
    super.applyStyles()
    this.applyTextStyles()
  }

  applyTextStyles() {
    if (!this.el) return

    // Font size as container query width units (cqw)
    // This scales with the container size
    const fontSizeCqw = this.fontSize

    // Normalize color - handle '0, 0, 0' format from theme data
    let color = this.fontColor || '#000000'
    if (color && !color.startsWith('#') && !color.startsWith('rgb')) {
      // Convert '0, 0, 0' to 'rgb(0, 0, 0)'
      color = `rgb(${color})`
    }

    Object.assign(this.el.style, {
      fontSize: `${fontSizeCqw}cqw`,
      color,
      fontFamily: 'Arial, sans-serif',
      lineHeight: '1.25',
      wordWrap: 'break-word',
      overflowWrap: 'break-word',
      whiteSpace: this.fontSize < TextDOMElement.SINGLE_LINE_THRESHOLD ? 'nowrap' : 'normal'
    })
  }

  applyDataAttributes() {
    super.applyDataAttributes()
    if (this.el) {
      this.el.dataset.elementText = this.text || ''
    }
  }

  updateTextContent() {
    if (this.textNode) {
      this.textNode.textContent = this.text || ''
    }
  }

  updateContent(data) {
    if (data.text !== undefined) this.text = data.text
    if (data.font_size !== undefined) this.fontSize = parseFloat(data.font_size)
    else if (data.fontSize !== undefined) this.fontSize = parseFloat(data.fontSize)
    else if (data.size !== undefined) this.fontSize = parseFloat(data.size)
    if (data.font_color !== undefined) this.fontColor = data.font_color
    else if (data.fontColor !== undefined) this.fontColor = data.fontColor
    else if (data.color !== undefined) this.fontColor = data.color

    this.updateTextContent()
    this.applyTextStyles()
    this.applyDataAttributes()
  }

  toJSON() {
    return {
      ...super.toJSON(),
      text: this.text,
      font_size: this.fontSize,
      font_color: this.fontColor
    }
  }
}

// Wallet text elements - same as text but sensitive (text not persisted)
export class WalletTextDOMElement extends TextDOMElement {
  static sensitive = true

  constructor(data) {
    super(data)
    this.sensitive = true
  }

  toJSON() {
    const json = super.toJSON()
    delete json.text  // Don't persist wallet text
    return json
  }
}

// Specific wallet text elements with dataKey for external data binding
export class PrivateKeyTextDOMElement extends WalletTextDOMElement {
  static dataKey = 'private_key_text'
}

export class PublicAddressTextDOMElement extends WalletTextDOMElement {
  static dataKey = 'public_address_text'
}

export class MnemonicTextDOMElement extends WalletTextDOMElement {
  static dataKey = 'mnemonic_text'
}
