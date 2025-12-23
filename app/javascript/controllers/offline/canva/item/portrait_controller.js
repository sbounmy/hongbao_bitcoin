import BaseController from "./base_controller"

// Handles portrait image on canvas with loading state for AI generation
export default class PortraitController extends BaseController {
  static drawer = "photo-drawer"

  constructor(name, data, canvaController) {
    super(name, data, canvaController)

    this.portraitImage = null
    this.placeholderImage = null
    this.loading = false
    this.loadingAnimationId = null
    this.placeholderUrl = data.placeholder || null

    // Load placeholder image if provided
    if (this.placeholderUrl) {
      this.loadPlaceholder(this.placeholderUrl)
    }

    // Listen for portrait events
    this.bindEvents()
  }

  bindEvents() {
    // Direct photo selection
    this.handleSelectedBound = this.handleSelected.bind(this)
    window.addEventListener("preview:selected", this.handleSelectedBound)

    // AI generation started
    this.handleLoadingBound = this.handleLoading.bind(this)
    window.addEventListener("portrait:loading", this.handleLoadingBound)

    // AI generation completed
    this.handleChangedBound = this.handleChanged.bind(this)
    window.addEventListener("portrait:changed", this.handleChangedBound)
  }

  destroy() {
    window.removeEventListener("preview:selected", this.handleSelectedBound)
    window.removeEventListener("portrait:loading", this.handleLoadingBound)
    window.removeEventListener("portrait:changed", this.handleChangedBound)
    this.stopLoadingAnimation()
  }

  loadPlaceholder(url) {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      this.placeholderImage = img
      if (!this.portraitImage) {
        this.canva.scheduleRedraw()
      }
    }
    img.src = url
  }

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

  handleLoading() {
    this.loading = true
    this.portraitImage = null
    this.startLoadingAnimation()
  }

  handleChanged(event) {
    this.loading = false
    this.stopLoadingAnimation()
    const url = event.detail?.url
    if (url) this.loadImage(url)
  }

  loadImage(url) {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      this.portraitImage = img
      this.canva.scheduleRedraw()
    }
    img.src = url
  }

  startLoadingAnimation() {
    if (this.loadingAnimationId) return

    const animate = () => {
      if (!this.loading) return
      this.canva.scheduleRedraw()
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

    if (this.loading) {
      this.drawSpinner(x, y, width, height)
      return
    }

    if (this.portraitImage) {
      this.drawPortraitImage(x, y, width, height)
    } else if (this.placeholderImage) {
      this.drawPortraitImage(x, y, width, height, this.placeholderImage)
    }
    // If no portrait and no placeholder, draw nothing (transparent)
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

  drawPortraitImage(x, y, boxWidth, boxHeight, img = this.portraitImage) {
    if (!img) return

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

  toJSON() {
    return {
      ...super.toJSON(),
      placeholder: this.placeholderUrl
    }
  }
}
