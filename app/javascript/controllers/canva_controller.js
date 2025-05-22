import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "canvaItem", "backgroundImage"]

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
    if (this.hasBackgroundImageTarget) {
      this.loadBackgroundImage()
    }
  }

  loadBackgroundImage() {
    if (!this.backgroundImageTarget) return

    const img = new Image()
    img.src = this.backgroundImageTarget.src
    img.onload = (event) => {
      this.backgroundImage = event.target
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
      canvaItem.dataset.controller = 'canva-item'
      canvaItem.dataset.canvaItemXValue = element.x
      canvaItem.dataset.canvaItemYValue = element.y
      canvaItem.dataset.canvaItemTextValue = element.text
      canvaItem.dataset.canvaItemNameValue = this.camelize(name)
      canvaItem.dataset.canvaItemTypeValue = name.endsWith('_qrcode') ? 'image' : (name.startsWith('mnemonic') ? 'mnemonic' : 'text')
      canvaItem.dataset.canvaItemFontSizeValue = element.size
      canvaItem.dataset.canvaItemFontColorValue = element.color
      canvaItem.dataset.canvaItemMaxTextWidthValue = element.maxTextWidth
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
    this.clear()
    this.canvaItemTargets.forEach(item => {
      const controller = this.application.getControllerForElementAndIdentifier(item, 'canva-item')
        controller.redraw(event)
    })
  }
}