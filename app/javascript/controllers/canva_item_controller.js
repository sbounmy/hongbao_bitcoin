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

    const x = this.canvaController.originalWidth * this.xValue
    const y = this.canvaController.originalHeight * this.yValue
    if (this.typeValue === 'text') {

      this.ctx.font = `${this.fontSizeValue}px Arial`
      this.ctx.fillStyle = this.fontColorValue
      this.wrapTextByChar(this.ctx, this.textValue || '', x, y, this.maxTextWidthValue, this.fontSizeValue + 1)

    } else if (this.typeValue === 'image') {
      let imageSize = this.fontSizeValue * this.canvaController.originalWidth
      this.ctx.drawImage(this.imageUrl, x, y, imageSize, imageSize)
    }
    else {
      this.drawTextMnemonic(this.textValue)
    }
  }

  async redraw({ detail }) {
    if (this.typeValue === 'text' || this.typeValue === 'mnemonic') {
      this.textValue = detail[this.nameValue]
      this.draw()
    } else {
      const qrImage = new Image()
      qrImage.src = await detail[this.nameValue]()
      qrImage.onload = () => {
        this.imageUrl = qrImage
        this.draw()
      }
    }
  }

  drawTextMnemonic(text) {
    const startX = this.canvaController.originalWidth * this.xValue
    const startY = this.canvaController.originalHeight * this.yValue

    this.ctx.font = `${this.fontSizeValue}px Arial`
    this.ctx.fillStyle = this.fontColorValue
    this.wrapTextByWord(this.ctx, this.textValue || '', startX, startY, this.maxTextWidthValue, this.fontSizeValue + 1)
  }

  wrapTextByChar(ctx, text, x, y, maxWidth, lineHeight) {
    let line = '';

    for (let i = 0; i < text.length; i++) {
      const testLine = line + text[i];
      const testWidth = line.length;

      if (testWidth > maxWidth && line !== '') {
        ctx.fillText(line, x, y);
        line = text[i];
        y += lineHeight;
      } else {
        line = testLine;
      }
    }

    if (line) {
      ctx.fillText(line, x, y);
    }
  }

  wrapTextByWord(ctx, text, x, y, maxWidth, lineHeight) {
    const words = text.split(' ');
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
  }

}