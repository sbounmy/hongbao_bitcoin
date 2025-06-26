import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    x: Number,
    y: Number,
    text: String,
    name: String,
    type: { type: String, default: 'text' },
    imageUrl: String,
    fontSize: { type: Number, default: 1 },
    fontColor: { type: String, default: 'black' },
    maxTextWidth: { type: Number, default: 30 },
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

    const dpr = this.canvaController.dpr || window.devicePixelRatio || 1;

    // Browsers can render fonts slightly differently between the DOM and the Canvas.
    // This small correction factor visually aligns the canvas font with the editor preview
    // by making the canvas font slightly smaller to compensate for it appearing larger.
    const fontCorrectionFactor = 1.04;
    const scaledFontSize = (this.fontSizeValue / dpr) / fontCorrectionFactor;

    const lineHeight = scaledFontSize * 1.25;
    const maxWidthPx = this.canvaController.originalWidth * (this.maxTextWidthValue / 100);

    if (this.typeValue === 'text') {
      this.ctx.font = `${scaledFontSize}px Arial`
      this.ctx.fillStyle = this.fontColorValue
      this.wrapTextByChar(this.ctx, this.textValue || '', x, y + scaledFontSize, maxWidthPx, lineHeight)

    } else if (this.typeValue === 'image') {
      let imageSize
      if (this.fontSizeValue > 1) {
        imageSize = (this.fontSizeValue / 100) * this.canvaController.originalWidth
      } else {
        imageSize = this.fontSizeValue * this.canvaController.originalWidth
      }
      this.ctx.drawImage(this.imageUrl, x, y, imageSize, imageSize)
    } else if (this.typeValue === 'mnemonic') {
      // REFACTOR: Pass calculated values to avoid duplicate code.
      this.drawTextMnemonic(this.textValue, x, y, scaledFontSize, lineHeight, maxWidthPx)
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