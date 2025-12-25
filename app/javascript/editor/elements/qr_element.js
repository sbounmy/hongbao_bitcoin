import { BaseElement } from "./base_element"

// QR code element - displays QR code images
export class QRElement extends BaseElement {
  constructor(data) {
    super(data)

    this.image = null
    this.imageUrl = data.image_url || data.imageUrl || null
    this.color = data.color || null

    // Load image if URL provided
    if (this.imageUrl) {
      this.loadImage(this.imageUrl)
    }
  }

  updateFromData(data) {
    super.updateFromData(data)

    const newUrl = data.image_url || data.imageUrl
    if (newUrl !== undefined && newUrl !== this.imageUrl) {
      this.imageUrl = newUrl
      if (this.imageUrl) {
        this.loadImage(this.imageUrl)
      } else {
        this.image = null
      }
    }

    if (data.color !== undefined) this.color = data.color
  }

  loadImage(url) {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      this.image = img
      // Notify that redraw is needed via callback if set
      this.onImageLoaded?.()
    }
    img.onerror = (err) => {
      console.error('[QRElement] Failed to load image:', url, err)
    }
    img.src = url
  }

  // Set image directly from base64 data
  setImageData(base64Data) {
    if (!base64Data) {
      this.image = null
      return
    }

    const img = new Image()
    img.onload = () => {
      this.image = img
      this.onImageLoaded?.()
    }
    img.src = base64Data
  }

  draw(ctx, bounds, canvasWidth, canvasHeight) {
    if (!ctx || !this.image) return

    const { x, y, width, height } = bounds

    // QR codes are always drawn as perfect squares
    // Use width to calculate size
    const size = (this.width / 100) * canvasWidth

    // Bottom-align: draw at y + height - size
    ctx.drawImage(this.image, x, y + height - size, size, size)
  }

  toJSON() {
    return {
      ...super.toJSON(),
      color: this.color
      // image_url is not persisted - comes from external source
    }
  }
}
