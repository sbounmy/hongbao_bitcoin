import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "canvaItem"]
  static values = {
    backgroundImage: String
  }

  connect() {
    this.initializeCanvas()
    this.loadBackgroundImage()
  }

  initializeCanvas() {
    // Get the canvas element
    const canvas = this.containerTarget

    // Get device pixel ratio
    const dpr = window.devicePixelRatio || 1

    // Store the original dimensions
    this.originalWidth = canvas.parentElement.offsetWidth
    this.originalHeight = canvas.parentElement.offsetHeight

    // Set the canvas size in pixels (multiplied by device pixel ratio)
    canvas.width = this.originalWidth * dpr
    canvas.height = this.originalHeight * dpr

    // Set the canvas display size through CSS
    canvas.style.width = `${this.originalWidth}px`
    canvas.style.height = `${this.originalHeight}px`

    // Get the context and scale it
    this.ctx = canvas.getContext('2d')

    // Clear any existing transforms
    this.ctx.setTransform(1, 0, 0, 1, 0, 0)

    // Apply the DPR scaling
    this.ctx.scale(dpr, dpr)

    // Enable image smoothing
    this.ctx.imageSmoothingEnabled = true
    this.ctx.imageSmoothingQuality = 'high'

    // Initial draw if background image exists
    if (this.hasBackgroundImageValue) {
      this.loadBackgroundImage()
    }
  }

  loadBackgroundImage() {
    if (!this.backgroundImageValue) return

    const img = new Image()
    img.src = this.backgroundImageValue
    img.onload = (event) => {
      this.backgroundImage = event.target
      this.dispatch("imageLoaded")
    }
  }

  backgroundImageChanged(event) {
    this.backgroundImageValue = event.detail.url
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
      canvaItem.dataset.controller = 'canva-item'
      canvaItem.dataset.canvaItemXValue = element.x
      canvaItem.dataset.canvaItemYValue = element.y
      canvaItem.dataset.canvaItemTextValue = element.text
      canvaItem.dataset.canvaItemNameValue = this.camelize(name)
      canvaItem.dataset.canvaItemTypeValue = name.endsWith('_qrcode') ? 'image' : (name.startsWith('mnemonic') ? 'mnemonic' : 'text')
      canvaItem.dataset.canvaItemFontSizeValue = element.size
      canvaItem.dataset.canvaItemFontColorValue = element.color
      canvaItem.classList.add('canva-item')
      canvaItem.classList.add('generated')
      canvaItem.dataset.canvaTarget = 'canvaItem'
      this.containerTarget.after(canvaItem)
    })
  }

  clear() {
    const dpr = window.devicePixelRatio || 1
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

  redraw(event) {
    this.clear()
    // Notify all canvaItem outlets to redraw
    // console.log("init redraw", this.canvaItemTargets)
    this.canvaItemTargets.forEach(item => {
        const controller = this.application.getControllerForElementAndIdentifier(item, 'canva-item')
        controller.redraw(event)
      })
  }
}