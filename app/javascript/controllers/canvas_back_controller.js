import CanvasBaseController from "controllers/canvas_base_controller"

export default class extends CanvasBaseController {
  static values = {
    ...super.values,
    mnemonic: String,
    privateKeyQr: String
  }


  updatePaper({ detail }) {
    const { paperId, imageBackUrl, elements } = detail
    this.paperIdValue = paperId
    this.imageUrlValue = imageBackUrl
    this.elementsValue = elements
    this.loadImage()
  }

  drawBill() {
    this.drawTextMnemonic(this.mnemonicValue, 'mnemonic')
    this.drawQRCode()
  }

  drawTextMnemonic(text, element) {
    const words = text.split(' ')
    const elementParams = this.elementsValue[element]
    const startX = this.canvasTarget.width * elementParams.x
    const startY = this.canvasTarget.height * elementParams.y

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

      this.ctx.fillStyle = elementParams.color
      this.ctx.font = `${elementParams.size}px Arial`
      this.ctx.fillText(`${index + 1}. ${word}`, x + 10, y + (boxHeight/2) + 4)
    })
  }

  drawQRCode() {
    const qrImage = new Image()
    qrImage.src = this.privateKeyQrValue

    qrImage.onload = () => {
      const coords = this.elementsValue.qrcode_private_key
      const qrWidth = this.canvasTarget.width * coords.size
      const qrHeight = this.canvasTarget.width * coords.size

      this.ctx.drawImage(qrImage,
        this.canvasTarget.width * coords.x,
        this.canvasTarget.height * coords.y,
        qrWidth,
        qrHeight
      )

      const svgString = `
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-6">
          <circle cx="12" cy="12" r="11" fill="white"/>
          <path fill-rule="evenodd" d="M12 1.5a5.25 5.25 0 0 0-5.25 5.25v3a3 3 0 0 0-3 3v6.75a3 3 0 0 0 3 3h10.5a3 3 0 0 0 3-3v-6.75a3 3 0 0 0-3-3v-3c0-2.9-2.35-5.25-5.25-5.25Zm3.75 8.25v-3a3.75 3.75 0 1 0-7.5 0v3h7.5Z" clip-rule="evenodd" />
        </svg>`


      const blob = new Blob([svgString], { type: 'image/svg+xml' })
      const url = URL.createObjectURL(blob)
      const svgImage = new Image()

      svgImage.onload = () => {
        const overlaySize = qrWidth * 0.25
        const centerX = (this.canvasTarget.width * coords.x) + (qrWidth / 2) - (overlaySize / 2)
        const centerY = (this.canvasTarget.height * coords.y) + (qrHeight / 2) - (overlaySize / 2)

        this.ctx.drawImage(svgImage, centerX, centerY, overlaySize, overlaySize)

        URL.revokeObjectURL(url)

        this.dispatch("done", {
          detail: {
            base64url: this.canvasData,
            paperId: this.paperIdValue,
            side: 'back'
          }
        })
      }

      svgImage.src = url
    }
  }
}