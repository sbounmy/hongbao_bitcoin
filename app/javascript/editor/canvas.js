// Canvas wrapper - handles rendering and coordinate conversion
export class Canvas {
  constructor(canvasElement, options = {}) {
    this.el = canvasElement
    this.ctx = null
    this.qualityScale = options.qualityScale || 3

    // Original dimensions (before scaling)
    this.originalWidth = 0
    this.originalHeight = 0

    // Display dimensions (CSS)
    this.displayWidth = 0
    this.displayHeight = 0

    // Background image
    this.backgroundImage = null
    this.backgroundColor = options.backgroundColor || '#ffffff'
  }

  // Get canvas context
  get context() {
    return this.ctx
  }

  get width() {
    return this.originalWidth
  }

  get height() {
    return this.originalHeight
  }

  // Initialize canvas with dimensions
  init(width, height) {
    this.originalWidth = width
    this.originalHeight = height

    // Set canvas internal size (high-res)
    this.el.width = width * this.qualityScale
    this.el.height = height * this.qualityScale

    // Setup context
    this.ctx = this.el.getContext('2d')
    this.ctx.setTransform(1, 0, 0, 1, 0, 0)
    this.ctx.scale(this.qualityScale, this.qualityScale)
    this.ctx.imageSmoothingEnabled = true
    this.ctx.imageSmoothingQuality = 'high'
  }

  // Resize canvas to fit container
  resize(containerWidth, containerHeight, strict = false) {
    if (strict) {
      // Use exact dimensions
      this.displayWidth = this.originalWidth
      this.displayHeight = this.originalHeight
    } else {
      // Fit to container maintaining aspect ratio
      const aspectRatio = this.originalWidth / this.originalHeight
      this.displayWidth = containerWidth
      this.displayHeight = containerWidth / aspectRatio

      if (this.displayHeight > containerHeight) {
        this.displayHeight = containerHeight
        this.displayWidth = containerHeight * aspectRatio
      }
    }

    this.el.style.width = `${this.displayWidth}px`
    this.el.style.height = `${this.displayHeight}px`
  }

  // Set background image
  setBackgroundImage(image) {
    this.backgroundImage = image
    if (image) {
      // Update dimensions from image
      this.init(image.width, image.height)
    }
  }

  // Load background image from URL
  loadBackgroundImage(url) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.crossOrigin = 'anonymous'
      img.onload = () => {
        this.setBackgroundImage(img)
        resolve(img)
      }
      img.onerror = (err) => {
        console.error('[Canvas] image load error:', err)
        reject(err)
      }
      img.src = url
    })
  }

  // Clear canvas and draw background
  clear() {
    if (!this.ctx) return

    this.ctx.clearRect(0, 0, this.originalWidth, this.originalHeight)

    if (this.backgroundImage) {
      this.ctx.drawImage(
        this.backgroundImage,
        0, 0,
        this.originalWidth,
        this.originalHeight
      )
    } else {
      this.ctx.fillStyle = this.backgroundColor
      this.ctx.fillRect(0, 0, this.originalWidth, this.originalHeight)
    }
  }

  // Convert client coordinates to canvas coordinates
  toCanvasCoords(clientX, clientY) {
    const rect = this.el.getBoundingClientRect()
    const scaleX = this.originalWidth / rect.width
    const scaleY = this.originalHeight / rect.height

    return {
      x: (clientX - rect.left) * scaleX,
      y: (clientY - rect.top) * scaleY
    }
  }

  // Convert canvas coordinates to percentage (0-100)
  toPercentage(canvasX, canvasY) {
    return {
      x: (canvasX / this.originalWidth) * 100,
      y: (canvasY / this.originalHeight) * 100
    }
  }

  // Convert percentage to canvas coordinates
  fromPercentage(percentX, percentY) {
    return {
      x: (percentX / 100) * this.originalWidth,
      y: (percentY / 100) * this.originalHeight
    }
  }

  // Convert client coordinates directly to percentage
  clientToPercentage(clientX, clientY) {
    const canvas = this.toCanvasCoords(clientX, clientY)
    return this.toPercentage(canvas.x, canvas.y)
  }

  // Get canvas bounds in client coordinates
  getBoundingRect() {
    return this.el.getBoundingClientRect()
  }

  // Export canvas as data URL
  toDataURL(type = 'image/png', quality = 1.0) {
    return this.el.toDataURL(type, quality)
  }
}
