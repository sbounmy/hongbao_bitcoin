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
    console.log("About to dispatch canvasReady event")
    this.dispatch("canvasReady")
    console.log("canvasReady event dispatched")
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

      this.drawText('Public Key', 'qrcode_public_key_label')
    }
  }
}