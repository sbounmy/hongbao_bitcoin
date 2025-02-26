import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "canvaItem"]
//   static outlets = ["canva-item"]
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
    img.onload = () => {
      this.backgroundImage = img
      this.redraw()
    }
  }

  backgroundImageChanged(event) {
    this.backgroundImageValue = event.detail.url
    this.clearCanvaItems()
    this.appendCanvaItems(event.detail.elements)
    this.loadBackgroundImage()
  }

  clearCanvaItems() {
    this.canvaItemTargets.forEach(item => {
      item.remove()
    })
  }

  appendCanvaItems(elements) {
    elements.forEach(element => {
      this.container.appendChild(element)
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

  redraw() {
    if (this.backgroundImage) {
      this.ctx.drawImage(
        this.backgroundImage,
        0,
        0,
        this.container.width,
        this.container.height
      )
    }

    // Notify all canvaItem outlets to redraw
    this.canvaItemTargets.forEach(item => {
        const controller = this.application.getControllerForElementAndIdentifier(item, 'canva-item')
        controller.ctx = this.ctx
        controller.draw()
      })
  }
}