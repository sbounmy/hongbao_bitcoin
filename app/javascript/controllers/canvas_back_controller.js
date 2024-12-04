import CanvasBaseController from "controllers/canvas_base_controller"

export default class extends CanvasBaseController {
  static values = {
    ...super.values,
    mnemonic: String,
    privateKeyQr: String
  }


  updatePaper({ detail }) {
    if (this.frozenValue) return
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

      this.drawText('Private Key', 'qrcode_private_key_label')
    }
  }
}