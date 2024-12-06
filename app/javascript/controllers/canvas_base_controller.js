import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    paperId: Number,
    context: String,
    elements: Object,
    imageUrl: String,
  }

  connect() {
    this.ctx = this.canvasTarget.getContext('2d')
    this.loadImage()
  }

  updatePaper({ detail }) {
    throw new Error('Must be implemented by child class')
  }

  loadImage() {
    const img = new Image()
    img.src = this.imageUrlValue
    img.height = 374.1
    img.width = 793.7

    img.onload = () => {
      this.canvasTarget.width = img.width
      this.canvasTarget.height = img.height

      this.ctx.save()
      this.ctx.clearRect(0, 0, this.canvasTarget.width, this.canvasTarget.height)
      this.ctx.drawImage(img, 0, 0, this.canvasTarget.width, this.canvasTarget.height)

      this.drawBill()
    }

    img.onerror = () => {
      console.error('Image failed to load.')
    }
  }

  drawBill() {
    throw new Error('Must be implemented by child class')
  }

  drawText(text, element) {
    const elementParams = this.elementsValue[element]
    this.ctx.fillStyle = `${elementParams.color}`
    this.ctx.font = `bold ${elementParams.size}px Arial`
    this.ctx.fillText(text,
      this.canvasTarget.width * elementParams.x,
      this.canvasTarget.height * elementParams.y
    )
  }

  get canvasData() {
    return this.canvasTarget.toDataURL('image/png')
  }

}