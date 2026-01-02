import { BaseElement } from './base_element'

// Text element rendered as DOM
// Uses CSS for fonts and text wrapping
export class TextElement extends BaseElement {
  static drawer = 'text-drawer'
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
      whiteSpace: this.fontSize < TextElement.SINGLE_LINE_THRESHOLD ? 'nowrap' : 'normal'
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

  // Override: corner handles change font size AND dimensions proportionally
  handleResize(handle, dxPercent, dyPercent) {
    const isCornerHandle = ['nw', 'ne', 'sw', 'se'].includes(handle)

    if (isCornerHandle) {
      // Sanitize inputs
      const dx = this._safeNumber(dxPercent, 0)
      const dy = this._safeNumber(dyPercent, 0)

      // Calculate font size delta based on drag direction
      let delta = 0
      switch (handle) {
        case 'se': delta = (dx + dy) / 2; break
        case 'nw': delta = (-dx - dy) / 2; break
        case 'ne': delta = (dx - dy) / 2; break
        case 'sw': delta = (-dx + dy) / 2; break
      }

      // Ensure oldFontSize is valid (prevent division by zero)
      const oldFontSize = Math.max(0.5, this._safeNumber(this.fontSize, 3))
      this.fontSize = Math.max(0.5, Math.min(50, oldFontSize + delta * 0.5))

      // Scale dimensions proportionally to font size change
      // Clamp scale to prevent extreme values
      const scale = Math.min(10, Math.max(0.1, this.fontSize / oldFontSize))
      let newWidth = this._safeNumber(this.width, 10) * scale
      let newHeight = this._safeNumber(this.height, 10) * scale

      // Ensure minimum size and clamp to reasonable bounds
      newWidth = Math.max(2, Math.min(200, newWidth))
      newHeight = Math.max(2, Math.min(200, newHeight))

      // Adjust position for nw/ne/sw corners (anchor opposite corner)
      let newX = this._safeNumber(this.x, 0)
      let newY = this._safeNumber(this.y, 0)
      const widthDelta = newWidth - this._safeNumber(this.width, 10)
      const heightDelta = newHeight - this._safeNumber(this.height, 10)

      switch (handle) {
        case 'nw':
          newX -= widthDelta
          newY -= heightDelta
          break
        case 'ne':
          newY -= heightDelta
          break
        case 'sw':
          newX -= widthDelta
          break
        // 'se' anchors top-left, no position change needed
      }

      // Clamp position to reasonable bounds
      newX = Math.max(-100, Math.min(200, newX))
      newY = Math.max(-100, Math.min(200, newY))

      this.x = newX
      this.y = newY
      this.width = newWidth
      this.height = newHeight

      return {
        font_size: this.fontSize,
        x: newX,
        y: newY,
        width: newWidth,
        height: newHeight
      }
    }

    // Edge handles: use default dimension resize
    return super.handleResize(handle, dxPercent, dyPercent)
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
export class WalletTextElement extends TextElement {
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
export class PrivateKeyTextElement extends WalletTextElement {
  static dataKey = 'private_key_text'
}

export class PublicAddressTextElement extends WalletTextElement {
  static dataKey = 'public_address_text'
}

export class MnemonicTextElement extends WalletTextElement {
  static dataKey = 'mnemonic_text'
}
