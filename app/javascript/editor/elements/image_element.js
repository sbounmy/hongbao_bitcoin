import { BaseElement } from "./base_element"

// Image element with loading state support
export class ImageElement extends BaseElement {
  static drawer = 'photo-drawer'

  constructor(data) {
    super(data)

    this.image = null
    this.placeholderImage = null
    this.loading = false
    this.loadingAnimationId = null
    this.placeholderUrl = data.placeholder || null

    // Load placeholder image if provided
    if (this.placeholderUrl) {
      this.loadPlaceholder(this.placeholderUrl)
    }
  }

  updateFromData(data) {
    super.updateFromData(data)

    if (data.placeholder !== undefined && data.placeholder !== this.placeholderUrl) {
      this.placeholderUrl = data.placeholder
      if (this.placeholderUrl) {
        this.loadPlaceholder(this.placeholderUrl)
      }
    }
  }

  loadPlaceholder(url) {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      this.placeholderImage = img
      if (!this.image) {
        this.onImageLoaded?.()
      }
    }
    img.src = url
  }

  // Load image from URL or file data
  loadImage(url) {
    this.loading = false
    this.stopLoadingAnimation()

    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      this.image = img
      this.onImageLoaded?.()
    }
    img.src = url
  }

  // Set loading state (e.g., during AI generation)
  setLoading(loading) {
    this.loading = loading
    if (loading) {
      this.image = null
      this.startLoadingAnimation()
    } else {
      this.stopLoadingAnimation()
    }
  }

  startLoadingAnimation() {
    if (this.loadingAnimationId) return

    const animate = () => {
      if (!this.loading) return
      this.onImageLoaded?.() // Trigger redraw
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

  draw(ctx, bounds, canvasWidth, canvasHeight) {
    if (!ctx) return

    const { x, y, width, height } = bounds

    if (this.loading) {
      this.drawSpinner(ctx, x, y, width, height)
      return
    }

    if (this.image) {
      this.drawImage(ctx, x, y, width, height, this.image)
    } else if (this.placeholderImage) {
      this.drawImage(ctx, x, y, width, height, this.placeholderImage)
    }
    // If no image and no placeholder, draw nothing (transparent)
  }

  drawSpinner(ctx, x, y, width, height) {
    const centerX = x + width / 2
    const centerY = y + height / 2
    const radius = Math.min(width, height) * 0.1

    ctx.save()
    ctx.strokeStyle = '#f97316' // Orange
    ctx.lineWidth = radius * 0.25
    ctx.lineCap = 'round'

    const startAngle = (Date.now() / 400) % (2 * Math.PI)
    ctx.beginPath()
    ctx.arc(centerX, centerY, radius, startAngle, startAngle + Math.PI * 1.5)
    ctx.stroke()
    ctx.restore()
  }

  drawImage(ctx, x, y, boxWidth, boxHeight, img) {
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

    ctx.drawImage(img, finalX, finalY, scaledWidth, scaledHeight)
  }

  destroy() {
    this.stopLoadingAnimation()
  }

  toJSON() {
    return {
      ...super.toJSON(),
      placeholder: this.placeholderUrl
    }
  }
}
