import BaseController from "./base_controller"

// Base QR code controller - wallet-sourced QR images
export default class QrcodeController extends BaseController {
  static drawer = "keys-drawer"

  constructor(name, data, canvaController) {
    super(name, data, canvaController)
    this.image = null
    this.imageUrl = data.image_url || null
  }

  draw() {
    if (!this.ctx || this.hidden || !this.image) return

    const { x, y, width, height } = this.getBounds()

    // For QR codes: always draw as perfect squares
    // Use width percentage to calculate size relative to canvas width
    const size = this.canvasWidth * (this.width / 100)

    // Bottom-align: draw at y + height - size so image bottom aligns with box bottom
    this.ctx.drawImage(this.image, x, y + height - size, size, size)
  }

  // Sync QR code from wallet data
  // Called by canva_controller when wallet changes
  syncFromWallet(wallet, key) {
    const qrData = wallet[key]
    if (!qrData) return

    const qrImage = new Image()
    qrImage.src = qrData // base64 string from wallet JSON
    qrImage.onload = () => {
      this.image = qrImage
      this.canva.scheduleRedraw()
    }
  }

  updateFromData(data) {
    super.updateFromData(data)
    if (data.image_url !== undefined) {
      this.imageUrl = data.image_url
      if (this.imageUrl) {
        this.loadImage(this.imageUrl)
      }
    }
  }

  loadImage(url) {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      this.image = img
      this.canva.scheduleRedraw()
    }
    img.src = url
  }

  toJSON() {
    return {
      ...super.toJSON()
      // QR image comes from wallet, not persisted
    }
  }
}
