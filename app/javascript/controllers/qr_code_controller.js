import { Controller } from "@hotwired/stimulus"
import QRCode from "qrcode"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: String,
    size: { type: Number, default: 150 },
    icon: { type: String, default: "" }
  }

  connect() {
    if (this.hasDataValue) {
      this.generateQR()
    }
  }

  generateQR() {
    QRCode.toCanvas(this.canvasTarget, this.dataValue, {
      width: this.sizeValue,
      margin: 4,
      color: {
        dark: '#000000',
        light: '#ffffff'
      }
    }).then(() => {
      if (this.hasIconValue && this.iconValue) {
        this.addIcon()
      }
    })
  }

  // Optional: Add icon to the center of QR code
  addIcon() {
    const canvas = this.canvasTarget
    const ctx = canvas.getContext('2d')
    const img = new Image()
    img.src = this.iconValue

    img.onload = () => {
      const size = this.sizeValue * 0.25 // Icon size (25% of QR code)
      const padding = 5

      // Draw white circle background
      ctx.beginPath()
      ctx.arc(canvas.width/2, canvas.height/2, size/2 + padding, 0, 2 * Math.PI)
      ctx.fillStyle = 'white'
      ctx.fill()

      // Draw the icon
      ctx.drawImage(
        img,
        canvas.width/2 - size/2,
        canvas.height/2 - size/2,
        size,
        size
      )
    }
  }
}