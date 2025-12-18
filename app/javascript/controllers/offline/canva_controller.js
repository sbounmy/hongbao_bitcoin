import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "canvaItem", "backgroundImage"]
  static values = {
    width: Number,   // Canvas width in pixels
    height: Number,  // Canvas height in pixels
    strict: Boolean  // Strict mode: use exact frame dimensions (for PDF)
  }

  connect() {
    // Defer initialization until element is visible (has dimensions)
    this.resizeObserver = new ResizeObserver(() => {
      const canvas = this.containerTarget
      if (canvas.parentElement.offsetWidth > 0 && !this.isInitialized) {
        this.isInitialized = true
        this.resizeObserver.disconnect()
        this.initializeCanvas()
        this.loadBackgroundImage()
      }
    })
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  initializeCanvas() {
    const canvas = this.containerTarget
    this.qualityScale = 3

    // Store container dimensions for display sizing
    this.containerWidth = canvas.parentElement.offsetWidth
    this.containerHeight = canvas.parentElement.offsetHeight

    // Initialize with fallback dimensions (will be updated when image loads)
    this.originalWidth = this.widthValue || this.containerWidth
    this.originalHeight = this.heightValue || this.containerHeight

    // Set initial canvas size
    this.setupCanvasSize(canvas)

    // Initial draw if background image exists
    if (this.hasBackgroundImageTarget) {
      this.loadBackgroundImage()
    }
  }

  setupCanvasSize(canvas) {
    // Internal resolution uses actual image dimensions for quality
    canvas.width = this.originalWidth * this.qualityScale
    canvas.height = this.originalHeight * this.qualityScale

    let displayWidth, displayHeight

    if (this.strictValue) {
      // Strict mode: use exact frame dimensions (for PDF printing)
      displayWidth = this.widthValue
      displayHeight = this.heightValue
    } else {
      // Responsive mode: fit container while maintaining aspect ratio
      const aspectRatio = this.originalWidth / this.originalHeight
      displayWidth = this.containerWidth
      displayHeight = displayWidth / aspectRatio

      // If too tall, constrain by height instead
      if (displayHeight > this.containerHeight) {
        displayHeight = this.containerHeight
        displayWidth = displayHeight * aspectRatio
      }
    }

    canvas.style.width = `${displayWidth}px`
    canvas.style.height = `${displayHeight}px`

    this.ctx = canvas.getContext('2d')
    this.ctx.setTransform(1, 0, 0, 1, 0, 0)
    this.ctx.scale(this.qualityScale, this.qualityScale)
    this.ctx.imageSmoothingEnabled = true
    this.ctx.imageSmoothingQuality = 'high'
  }

  loadBackgroundImage() {
    if (!this.backgroundImageTarget) return

    const img = new Image()
    img.src = this.backgroundImageTarget.src
    img.onload = (event) => {
      this.backgroundImage = event.target

      // Use actual image dimensions for correct aspect ratio
      // This matches composition.rb which uses template_image.width/height
      this.originalWidth = this.backgroundImage.width
      this.originalHeight = this.backgroundImage.height
      this.setupCanvasSize(this.containerTarget)

      this.dispatch("imageLoaded")
    }
  }

  backgroundImageChanged(event) {
    this.backgroundImageTarget.src = event.detail.url
    this.clearCanvaItems()
    this.createCanvaItems(event.detail.elements)
    this.loadBackgroundImage()
  }

  clearCanvaItems() {
    this.canvaItemTargets.forEach(item => {
      item.remove()
    })
  }
  camelize(name) {
    return name
      .split('_')
      .map((word, index) =>
        index === 0 ? word.toLowerCase() : word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
      )
      .join('')
  }

  createCanvaItems(elements) {
    Object.keys(elements).forEach(name => {
      const element = elements[name]
      const canvaItem = document.createElement('div')
      const isQrCode = name.endsWith('_qrcode')
      const isMnemonic = name.startsWith('mnemonic')

      canvaItem.dataset.controller = 'canva-item'
      canvaItem.dataset.canvaItemXValue = element.x
      canvaItem.dataset.canvaItemYValue = element.y
      canvaItem.dataset.canvaItemTextValue = element.text
      canvaItem.dataset.canvaItemNameValue = this.camelize(name)
      canvaItem.dataset.canvaItemTypeValue = isQrCode ? 'image' : (isMnemonic ? 'mnemonic' : 'text')

      // New unified properties: width and height for all elements
      canvaItem.dataset.canvaItemWidthValue = element.width
      canvaItem.dataset.canvaItemHeightValue = element.height

      // For text elements, size is the font size
      // For QR codes, size property shouldn't exist (using width/height instead)
      if (!isQrCode) {
        canvaItem.dataset.canvaItemFontSizeValue = element.size
      }

      canvaItem.dataset.canvaItemFontColorValue = element.color
      canvaItem.classList.add('canva-item')
      canvaItem.classList.add('generated')
      canvaItem.dataset.canvaTarget = 'canvaItem'
      this.containerTarget.after(canvaItem)
    })
  }

  clear() {
    if (!this.ctx) return

    this.ctx.clearRect(0, 0, this.originalWidth, this.originalHeight)
    if (this.backgroundImage) {
      this.ctx.drawImage(
        this.backgroundImage,
        0,
        0,
        this.originalWidth,
        this.originalHeight
      )
    }
  }

  hide(names) {
    names = [names].flat()
    this.canvaItemTargets.forEach(item => {
      if (names.includes(item.dataset.canvaItemNameValue)) {
        item.dataset.canvaItemHiddenValue = true
      }
    })
  }

  show(names) {
    names = [names].flat()
    this.canvaItemTargets.forEach(item => {
      if (names.includes(item.dataset.canvaItemNameValue)) {
        item.dataset.canvaItemHiddenValue = false
      }
    })
  }

  // Redraw the canvas without any changing data (usually ui mode changed)
  refresh(event) {
    if (!this.isInitialized) return

    this.hide(event.detail.hide)
    this.show(event.detail.show)
    this.clear()
    this.canvaItemTargets.forEach(item => {
      const controller = this.application.getControllerForElementAndIdentifier(item, 'canva-item')
      controller.draw()
    })
  }

  // Redraw the canvas with changing data from wallet generation
  redraw(event) {
    if (!this.isInitialized) return

    this.clear()
    this.canvaItemTargets.forEach(item => {
      const controller = this.application.getControllerForElementAndIdentifier(item, 'canva-item')
        controller.redraw(event)
    })
  }
}
