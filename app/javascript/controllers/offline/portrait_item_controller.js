import CanvaItemController from "./canva_item_controller"

// Handles portrait image on canvas with loading state for AI generation
export default class extends CanvaItemController {
  static values = {
    ...CanvaItemController.values,
    loading: Boolean
  }

  connect() {
    super.connect()
    this.portraitImage = null
    this.loadingAnimationId = null
  }

  disconnect() {
    this.stopLoadingAnimation()
  }

  // Called by preview:selected@window - direct photo selection
  handleSelected(event) {
    const { file, url } = event.detail || {}

    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => this.loadImage(e.target.result)
      reader.readAsDataURL(file)
    } else if (url) {
      this.loadImage(url)
    }
  }

  // Called by portrait:loading@window - AI generation started
  handleLoading() {
    this.loadingValue = true
    this.portraitImage = null
    this.startLoadingAnimation()
  }

  // Called by portrait:changed@window - AI generation completed
  handleChanged(event) {
    this.loadingValue = false
    this.stopLoadingAnimation()
    const url = event.detail?.url
    if (url) this.loadImage(url)
  }

  loadImage(url) {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      this.portraitImage = img
      this.canvaController?.redrawAll()
    }
    img.src = url
  }

  startLoadingAnimation() {
    if (this.loadingAnimationId) return

    const animate = () => {
      if (!this.loadingValue) return
      this.canvaController?.redrawAll()
      this.loadingAnimationId = requestAnimationFrame(animate)
    }
    animate()
  }

  stopLoadingAnimation() {
    if (this.loadingAnimationId) {
      cancelAnimationFrame(this.loadingAnimationId)
      this.loadingAnimationId = null
    }
  }

  draw() {
    if (!this.ctx) return
    const { x, y, width, height } = this.getBounds()

    if (this.loadingValue) {
      this.drawSpinner(x, y, width, height)
      return
    }

    if (this.portraitImage) {
      this.drawPortraitImage(x, y, width, height)
    }
  }

  drawSpinner(x, y, width, height) {
    const centerX = x + width / 2
    const centerY = y + height / 2
    const radius = Math.min(width, height) * 0.1

    this.ctx.save()
    this.ctx.strokeStyle = '#f97316' // Orange
    this.ctx.lineWidth = radius * 0.25
    this.ctx.lineCap = 'round'

    const startAngle = (Date.now() / 400) % (2 * Math.PI)
    this.ctx.beginPath()
    this.ctx.arc(centerX, centerY, radius, startAngle, startAngle + Math.PI * 1.5)
    this.ctx.stroke()
    this.ctx.restore()
  }

  drawPortraitImage(x, y, boxWidth, boxHeight) {
    const img = this.portraitImage

    // Scale to fit bounding box while maintaining aspect ratio
    const scaleX = boxWidth / img.width
    const scaleY = boxHeight / img.height
    const scale = Math.min(scaleX, scaleY)

    const scaledWidth = img.width * scale
    const scaledHeight = img.height * scale

    // Center horizontally, align to bottom of bounding box
    const finalX = x + (boxWidth - scaledWidth) / 2
    const finalY = y + (boxHeight - scaledHeight)

    this.ctx.drawImage(
      img,
      finalX,
      finalY,
      scaledWidth,
      scaledHeight
    )
  }
}
