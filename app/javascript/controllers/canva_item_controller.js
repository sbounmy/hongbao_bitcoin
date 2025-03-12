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
    fontColor: { type: String, default: 'black' }
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
    if (!this.ctx) return

    const x = this.canvaController.originalWidth * this.xValue
    const y = this.canvaController.originalHeight * this.yValue
    if (this.typeValue === 'text') {
      this.ctx.font = `${this.fontSizeValue}px Arial`
      this.ctx.fillStyle = this.fontColorValue
      this.ctx.fillText(this.textValue || '', x, y)

    } else if (this.typeValue === 'image') {
      let imageSize = this.fontSizeValue * this.canvaController.originalWidth
      this.ctx.drawImage(this.imageUrl, x, y, imageSize, imageSize)
    }
    else{
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
    const words = text.split(' ')
    const startX = this.canvaController.originalWidth * this.xValue
    const startY = this.canvaController.originalHeight * this.yValue

    const boxWidth = 100
    const boxHeight = 30
    const gapX = 5
    const gapY = 2
    const cols = 4

    words.forEach((word, index) => {
      const col = index % cols
      const row = Math.floor(index / cols)

      const x = startX + (col * (boxWidth + gapX))
      const y = startY + (row * (boxHeight + gapY))

      this.ctx.fillStyle = this.fontColorValue
      this.ctx.font = `${this.fontSizeValue}px Arial`
      this.ctx.fillText(`${index + 1}. ${word}`, x + 10, y + (boxHeight/2) + 4)
    })
  }
}