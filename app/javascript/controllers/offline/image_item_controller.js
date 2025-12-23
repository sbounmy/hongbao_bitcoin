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

  // Sync QR code from wallet JSON (source of truth)
  // Called by canva_controller.syncFromWalletJson()
  syncFromWallet(wallet) {
    console.log(wallet)
    console.log('nameValue:',this.nameValue)
    const qrData = wallet[this.nameValue]
    if (!qrData) return

    const qrImage = new Image()
    qrImage.src = qrData  // base64 string from wallet JSON
    qrImage.onload = () => {
      this.image = qrImage
      // Draw immediately when image loads (async)
      // redrawAll() may have already been called by the time this fires
      this.draw()
    }
  }
}
