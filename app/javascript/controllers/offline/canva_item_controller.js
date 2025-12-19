import { Controller } from "@hotwired/stimulus"

// Base class for all canva items (text, image, portrait)
// Child classes should override draw() method
export default class extends Controller {
  static values = {
    x: Number,
    y: Number,
    width: { type: Number, default: 30 },
    height: { type: Number, default: 30 },
    name: String,
    hidden: { type: Boolean, default: false }
  }

  connect() {
    this._canvaController = this.application
      .getControllerForElementAndIdentifier(
        this.element.closest('[data-controller~="canva"]'),
        'canva'
      )
  }

  get canvaController() {
    return this._canvaController
  }

  get ctx() {
    return this.canvaController?.ctx
  }

  get canvasWidth() {
    return this.canvaController?.originalWidth
  }

  get canvasHeight() {
    return this.canvaController?.originalHeight
  }

  getBounds() {
    return {
      x: this.canvasWidth * (this.xValue / 100),
      y: this.canvasHeight * (this.yValue / 100),
      width: this.canvasWidth * (this.widthValue / 100),
      height: this.canvasHeight * (this.heightValue / 100)
    }
  }

  // Override in subclasses
  draw() {
    console.warn('draw() not implemented for', this.constructor.name)
  }

  // Override in subclasses if needed
  redraw(event) {
    this.draw()
  }
}
