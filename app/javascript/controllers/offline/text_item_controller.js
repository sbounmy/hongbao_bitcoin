import CanvaItemController from "./canva_item_controller"

// Handles text and mnemonic rendering on canvas
export default class extends CanvaItemController {
  static values = {
    ...CanvaItemController.values,
    text: String,
    type: { type: String, default: 'text' }, // 'text' or 'mnemonic'
    fontSize: { type: Number, default: 1 },
    fontColor: { type: String, default: 'black' }
  }

  draw() {
    if (!this.ctx || this.hiddenValue) return

    const { x, y } = this.getBounds()
    const maxWidthPx = this.canvasWidth * (this.widthValue / 100)

    // Font size is a percentage of canvas width
    const fontCorrectionFactor = 0.95
    const fontSizePx = (this.fontSizeValue / 100) * this.canvasWidth
    const scaledFontSize = fontSizePx / fontCorrectionFactor
    const lineHeight = scaledFontSize * 1.25

    this.ctx.font = `${scaledFontSize}px Arial`
    this.ctx.fillStyle = this.fontColorValue

    if (this.typeValue === 'mnemonic') {
      this.wrapTextByWord(this.textValue || '', x, y + scaledFontSize, maxWidthPx, lineHeight)
    } else {
      this.wrapTextByChar(this.textValue || '', x, y + scaledFontSize, maxWidthPx, lineHeight)
    }
  }

  redraw({ detail }) {
    this.textValue = detail[this.nameValue] || ''
    this.draw()
  }

  wrapTextByChar(text, x, y, maxWidth, lineHeight) {
    const ctx = this.ctx
    const paragraphs = text.split('\n')

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
        } else {
          line = testLine
        }
      }
      ctx.fillText(line, x, y)
      if (p < paragraphs.length - 1) {
        y += lineHeight
      }
    }
  }

  wrapTextByWord(text, x, y, maxWidth, lineHeight) {
    const ctx = this.ctx
    const paragraphs = text.split('\n')

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
        } else {
          line = testLine
        }
      }
      ctx.fillText(line, x, y)
      if (p < paragraphs.length - 1) {
        y += lineHeight
      }
    }
  }
}
