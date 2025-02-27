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

    if (this.typeValue === 'text') {
        this.ctx.font = `${this.fontSizeValue}px Arial`
        this.ctx.fillStyle = this.fontColorValue

        const maxWidth = this.ctx.canvas.width * 0.8

        const wrapText = (text, x, y, maxWidth, lineHeight) => {
            const words = text.split(' ')
            let line = ''

            for (let n = 0; n < words.length; n++) {
                const testLine = line + words[n] + ' '
                const metrics = this.ctx.measureText(testLine)
                const testWidth = metrics.width

                if (testWidth > maxWidth && n > 0) {
                    this.ctx.fillText(line, x, y)
                    line = words[n] + ' '
                    y += lineHeight
                } else {
                    line = testLine
                }
            }
            this.ctx.fillText(line, x, y)
        }

        const lineHeight = this.fontSizeValue * 2
        wrapText(this.textValue || '', x, y, maxWidth, lineHeight)
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