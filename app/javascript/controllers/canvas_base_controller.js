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

  typewriterText(text, element, x = null, y = null) {
    const elementParams = this.elementsValue[element]
    const startX = x !== null ? x : this.canvasTarget.width * elementParams.x
    const startY = y !== null ? y : this.canvasTarget.height * elementParams.y
    const color = elementParams.color
    const fontSize = elementParams.size

    this.ctx.fillStyle = color
    this.ctx.font = `bold ${fontSize}px Arial`

    let index = 0
    const interval = setInterval(() => {
      if (index < text.length) {
        this.ctx.fillText(text[index], startX + this.ctx.measureText(text.slice(0, index)).width, startY)
        index++
      } else {
        clearInterval(interval)
      }
    }, 100) // Adjust the speed of the typewriter effect by changing the interval time
  }
}