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
    this.container = this.containerTarget
    this.ctx = this.container.getContext('2d')
  }

  loadBackgroundImage() {
    if (!this.backgroundImageValue) return

    const img = new Image()
    img.src = this.backgroundImageValue
    img.onload = (event) => {
      console.log("loadBackgroundImage", event.target)
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
      canvaItem.dataset.canvaItemTypeValue = name.endsWith('_qrcode') ? 'image' : 'text'
      canvaItem.dataset.canvaItemFontSizeValue = element.size
      canvaItem.dataset.canvaItemFontColorValue = element.color
      canvaItem.classList.add('canva-item')
      canvaItem.classList.add('generated')
      canvaItem.dataset.canvaTarget = 'canvaItem'
      this.container.after(canvaItem)
    })
  }

  clear() {
    this.ctx.clearRect(0, 0, this.container.width, this.container.height)
    if (this.backgroundImage) {
        this.ctx.drawImage(
          this.backgroundImage,
          0,
          0,
          this.container.width,
          this.container.height
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