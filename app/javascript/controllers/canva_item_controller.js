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

    const x = this.ctx.canvas.width * this.xValue
    const y = this.ctx.canvas.height * this.yValue

    // Use the correct value properties
    // Clear the entire canvas first
    if (this.typeValue === 'text') {
        this.ctx.font = `${this.fontSizeValue}px Arial`
        this.ctx.fillStyle = this.fontColorValue
        this.ctx.fillText(this.textValue || '', x, y)
    } else if (this.typeValue === 'image') {
      let imageSize = this.fontSizeValue*this.ctx.canvas.width
      this.ctx.drawImage(this.imageUrl, x, y,imageSize,imageSize)
    }
  }

  async redraw({ detail }) {
    if (this.typeValue === 'text') {
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
}