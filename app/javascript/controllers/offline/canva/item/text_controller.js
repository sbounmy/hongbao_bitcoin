import BaseController from "./base_controller"

// Custom text item - user-created text that persists to elements JSON
export default class TextController extends BaseController {
  static drawer = "text-edit-drawer"
  static SINGLE_LINE_THRESHOLD = 1.5

  constructor(name, data, canvaController) {
    super(name, data, canvaController)

    this.text = data.text || ""
    // Accept both font_size and size (legacy) - parse as float since theme data uses strings
    this.fontSize = parseFloat(data.font_size ?? data.size) || 3
    this.fontColor = data.font_color || data.color || "black"
  }

  // Override to dispatch event for text-edit-drawer binding
  openDrawer() {
    // Dispatch event so text-edit drawer can bind to this item
    document.dispatchEvent(new CustomEvent("text-edit:open", {
      detail: { item: this }
    }))

    super.openDrawer()
  }

  updateFromData(data) {
    super.updateFromData(data)
    if (data.text !== undefined) this.text = data.text
    if (data.font_size !== undefined) this.fontSize = parseFloat(data.font_size)
    else if (data.size !== undefined) this.fontSize = parseFloat(data.size)
    if (data.font_color !== undefined) this.fontColor = data.font_color
    else if (data.color !== undefined) this.fontColor = data.color
  }

  draw() {
    if (!this.ctx || this.hidden) return

    const { x, y } = this.getBounds()
    const maxWidthPx = this.canvasWidth * (this.width / 100)

    // Font size is a percentage of canvas width
    const fontCorrectionFactor = 0.95
    const fontSizePx = (this.fontSize / 100) * this.canvasWidth
    const scaledFontSize = fontSizePx / fontCorrectionFactor
    const lineHeight = scaledFontSize * 1.25

    this.ctx.font = `${scaledFontSize}px Arial`
    this.ctx.fillStyle = this.fontColor

    // Below threshold: single line, no wrapping
    const forceSingleLine = this.fontSize < this.constructor.SINGLE_LINE_THRESHOLD

    if (forceSingleLine) {
      this.ctx.fillText(this.text || '', x, y + scaledFontSize)
      this._calculatedHeight = lineHeight / this.canvasHeight * 100
    } else {
      const linesDrawn = this.wrapTextByChar(this.text || '', x, y + scaledFontSize, maxWidthPx, lineHeight)
      this._calculatedHeight = (linesDrawn * lineHeight) / this.canvasHeight * 100
    }
  }

  getCalculatedHeight() {
    return this._calculatedHeight || this.height
  }

  wrapTextByChar(text, x, y, maxWidth, lineHeight) {
    const ctx = this.ctx
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

  wrapTextByWord(text, x, y, maxWidth, lineHeight) {
    const ctx = this.ctx
    const paragraphs = text.split('\n')
    let lineCount = 0

    for (let p = 0; p < paragraphs.length; p++) {
      const paragraph = paragraphs[p]
      const words = paragraph.split(' ')
      let line = ''

      for (let n = 0; n < words.length; n++) {
        const testLine = line + words[n] + ' '
        const metrics = ctx.measureText(testLine)
        const testWidth = metrics.width

        if (testWidth > maxWidth && n > 0) {
          ctx.fillText(line, x, y)
          line = words[n] + ' '
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
