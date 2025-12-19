import CanvaItemController from "./canva_item_controller"

// Handles QR code images on canvas
export default class extends CanvaItemController {
  static values = {
    ...CanvaItemController.values,
    imageUrl: String
  }

  connect() {
    super.connect()
    this.image = null
  }

  draw() {
    if (!this.ctx || this.hiddenValue || !this.image) return

    const { x, y, width, height } = this.getBounds()

    // For QR codes: always draw as perfect squares
    // Use width percentage to calculate size relative to canvas width
    const size = this.canvasWidth * (this.widthValue / 100)

    // Bottom-align: draw at y + height - size so image bottom aligns with box bottom
    this.ctx.drawImage(this.image, x, y + height - size, size, size)
  }

  async redraw({ detail }) {
    const src = await detail[this.nameValue]()
    if (!src) return

    const qrImage = new Image()
    qrImage.src = src
    qrImage.onload = () => {
      this.image = qrImage
      this.draw()
    }
  }
}
