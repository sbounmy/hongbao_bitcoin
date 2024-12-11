import CanvasBaseController from "controllers/canvas_base_controller"

export default class extends CanvasBaseController {
  static values = {
    ...super.values,
    address: String,
    publicKeyQr: String
  }

  updatePaper({ detail }) {
    const { paperId, imageFrontUrl, elements } = detail
    this.paperIdValue = paperId
    this.imageUrlValue = imageFrontUrl
    this.elementsValue = elements
    this.loadImage()
  }


  drawBill() {
    this.drawText(this.addressValue, 'public_key_address')
    this.drawQRCode()
  }

  drawQRCode() {
    const qrImage = new Image()
    qrImage.src = this.publicKeyQrValue

    qrImage.onload = () => {
      const coords = this.elementsValue.qrcode_public_key
      const qrWidth = this.canvasTarget.width * coords.size
      const qrHeight = this.canvasTarget.width * coords.size

      this.ctx.drawImage(qrImage,
        this.canvasTarget.width * coords.x,
        this.canvasTarget.height * coords.y,
        qrWidth,
        qrHeight
      )

      const svgIcon = `
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
        <circle cx="12" cy="12" r="11" fill="white"/>
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9.004 9.004 0 0 0 8.716-6.747M12 21a9.004 9.004 0 0 1-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 0 1 7.843 4.582M12 3a8.997 8.997 0 0 0-7.843 4.582m15.686 0A11.953 11.953 0 0 1 12 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0 1 21 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0 1 12 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 0 1 3 12c0-1.605.42-3.113 1.157-4.418" />
        </svg>
      `

      const svgBlob = new Blob([svgIcon], { type: 'image/svg+xml;charset=utf-8' })
      const url = URL.createObjectURL(svgBlob)
      const iconImage = new Image()
      iconImage.src = url

      iconImage.onload = () => {
        const iconSize = qrWidth * 0.25
        const iconX = this.canvasTarget.width * coords.x + (qrWidth - iconSize) / 2
        const iconY = this.canvasTarget.height * coords.y + (qrHeight - iconSize) / 2

        this.ctx.drawImage(iconImage, iconX, iconY, iconSize, iconSize)

        this.dispatch("done", {
          detail: {
            base64url: this.canvasData,
            paperId: this.paperIdValue,
            side: 'front'
          }
        })

        // Revoke the object URL after use
        URL.revokeObjectURL(url)
      }
    }
  }
}