import { BaseElement } from "./base_element"

// Text element - user-created text that persists to elements JSON
export class TextElement extends BaseElement {
  static drawer = 'text-edit-drawer'
  static SINGLE_LINE_THRESHOLD = 1.5

  constructor(data) {
    super(data)

    this.text = data.text || ""
    // Accept both font_size and fontSize (normalize to fontSize internally)
    this.fontSize = parseFloat(data.font_size ?? data.fontSize ?? data.size) || 3
    this.fontColor = data.font_color || data.fontColor || data.color || "#000000"

    // Calculated height after text wrapping
    this._calculatedHeight = null
  }

  updateFromData(data) {
    super.updateFromData(data)
    if (data.text !== undefined) this.text = data.text
    if (data.font_size !== undefined) this.fontSize = parseFloat(data.font_size)
    else if (data.fontSize !== undefined) this.fontSize = parseFloat(data.fontSize)
    else if (data.size !== undefined) this.fontSize = parseFloat(data.size)
    if (data.font_color !== undefined) this.fontColor = data.font_color
    else if (data.fontColor !== undefined) this.fontColor = data.fontColor
    else if (data.color !== undefined) this.fontColor = data.color
  }

  draw(ctx, bounds, canvasWidth, canvasHeight) {
    if (!ctx || !this.text) return

    const { x, y, width: maxWidthPx } = bounds

    // Font size is a percentage of canvas width
    const fontCorrectionFactor = 0.95
    const fontSizePx = (this.fontSize / 100) * canvasWidth
    const scaledFontSize = fontSizePx / fontCorrectionFactor
    const lineHeight = scaledFontSize * 1.25

    ctx.font = `${scaledFontSize}px Arial`
    ctx.fillStyle = this.fontColor

    // Below threshold: single line, no wrapping
    const forceSingleLine = this.fontSize < TextElement.SINGLE_LINE_THRESHOLD

    if (forceSingleLine) {
      ctx.fillText(this.text, x, y + scaledFontSize)
      this._calculatedHeight = (lineHeight / canvasHeight) * 100
    } else {
      const linesDrawn = this.wrapTextByChar(ctx, this.text, x, y + scaledFontSize, maxWidthPx, lineHeight)
      this._calculatedHeight = (linesDrawn * lineHeight / canvasHeight) * 100
    }
  }

  getCalculatedHeight() {
    return this._calculatedHeight || this.height
  }

  wrapTextByChar(ctx, text, x, y, maxWidth, lineHeight) {
    const paragraphs = text.split('\n')
    let lineCount = 0

    for (let p = 0; p < paragraphs.length; p++) {
      const paragraph = paragraphs[p]
      let line = ''

      for (let i = 0; i < paragraph.length; i++) {
        const testLine = line + paragraph[i]
        const metrics = ctx.measureText(testLine)
        const testWidth = metrics.width

        if (testWidth > maxWidth && i > 0) {
          ctx.fillText(line, x, y)
          line = paragraph[i]
          y += lineHeight
          lineCount++
        } else {
          line = testLine
        }
      }
      ctx.fillText(line, x, y)
      lineCount++
      if (p < paragraphs.length - 1) {
        y += lineHeight
      }
    }
    return lineCount
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
