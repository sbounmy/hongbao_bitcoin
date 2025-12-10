import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    x: Number,
    y: Number,
    text: String,
    name: String,
    type: { type: String, default: 'text' },
    imageUrl: String,
    width: { type: Number, default: 30 },      // Percentage of canvas width
    height: { type: Number, default: 30 },     // Percentage of canvas height
    fontSize: { type: Number, default: 1 },    // Font size for text elements
    fontColor: { type: String, default: 'black' },
    hidden: { type: Boolean, default: false }
  }

  connect() {
    this.canvaController = this.application
      .getControllerForElementAndIdentifier(
        this.element.closest('[data-controller="canva"]'),
        'canva'
      )
    this.ctx = this.canvaController.ctx
  }

  draw() {
    if (!this.ctx || this.hiddenValue) return

    const x = this.canvaController.originalWidth * (this.xValue / 100)
    const y = this.canvaController.originalHeight * (this.yValue / 100)

    if (this.typeValue === 'text' || this.typeValue === 'mnemonic') {
      // Width is the max text width in percentage of canvas width
      const maxWidthPx = this.canvaController.originalWidth * (this.widthValue / 100)

      // Font size is now a percentage of the canvas width
      const fontCorrectionFactor = 0.95
      const fontSizePx = (this.fontSizeValue / 100) * this.canvaController.originalWidth
      const scaledFontSize = fontSizePx / fontCorrectionFactor
      const lineHeight = scaledFontSize * 1.25

      this.ctx.font = `${scaledFontSize}px Arial`
      this.ctx.fillStyle = this.fontColorValue

      if (this.typeValue === 'text') {
        this.wrapTextByChar(this.ctx, this.textValue || '', x, y + scaledFontSize, maxWidthPx, lineHeight)
      } else { // mnemonic
        this.wrapTextByWord(this.ctx, this.textValue || '', x, y + scaledFontSize, maxWidthPx, lineHeight)
      }

    } else if (this.typeValue === 'image') {
      // For QR codes: always draw as perfect squares
      // Use width percentage to calculate size relative to canvas width
      const size = this.canvaController.originalWidth * (this.widthValue / 100)
      const height = this.canvaController.originalHeight * (this.heightValue / 100)
      // Bottom-align: draw at y + height - size so image bottom aligns with box bottom
      this.ctx.drawImage(this.imageUrl, x, y + height - size, size, size)
    }
  }

  async redraw({ detail }) {
    if (this.typeValue === 'text' || this.typeValue === 'mnemonic') {
      this.textValue = detail[this.nameValue]
      this.draw()
    } else {
      const src = await detail[this.nameValue]()
      if (!src) return
      const qrImage = new Image()
      qrImage.src = src
      qrImage.onload = () => {
        this.imageUrl = qrImage
        this.draw()
      }
    }
  }

  drawTextMnemonic(text, startX, startY, scaledFontSize, lineHeight, maxWidthPx) {
    this.ctx.font = `${scaledFontSize}px Arial`
    this.ctx.fillStyle = this.fontColorValue
    this.wrapTextByWord(this.ctx, text || '', startX, startY + scaledFontSize, maxWidthPx, lineHeight)
  }

  wrapTextByChar(ctx, text, x, y, maxWidth, lineHeight) {
    const paragraphs = text.split('\n');
    for (let p = 0; p < paragraphs.length; p++) {
      const paragraph = paragraphs[p];
      let line = '';
      for (let i = 0; i < paragraph.length; i++) {
        const testLine = line + paragraph[i];
        const metrics = ctx.measureText(testLine);
        const testWidth = metrics.width;
        if (testWidth > maxWidth && i > 0) {
          ctx.fillText(line, x, y);
          line = paragraph[i];
          y += lineHeight;
        } else {
          line = testLine;
        }
      }
      ctx.fillText(line, x, y);
      if (p < paragraphs.length - 1) {
        y += lineHeight;
      }
    }
  }

  wrapTextByWord(ctx, text, x, y, maxWidth, lineHeight) {
    const paragraphs = text.split('\n');
    for (let p = 0; p < paragraphs.length; p++) {
      const paragraph = paragraphs[p];
      const words = paragraph.split(' ');
      let line = '';

      for (let n = 0; n < words.length; n++) {
        const testLine = line + words[n] + ' ';
        const metrics = ctx.measureText(testLine);
        const testWidth = metrics.width;

        if (testWidth > maxWidth && n > 0) {
          ctx.fillText(line, x, y);
          line = words[n] + ' ';
          y += lineHeight;
        } else {
          line = testLine;
        }
      }
      ctx.fillText(line, x, y);
      if (p < paragraphs.length - 1) {
        y += lineHeight;
      }
    }
  }

}