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
    hidden: { type: Boolean, default: false },
    // Editor support
    selected: { type: Boolean, default: false },
    presence: { type: Boolean, default: true },  // true = required item, cannot delete
    rotation: { type: Number, default: 0 },
    drawer: String  // ID of drawer to open on click
  }

  connect() {
    this._canvaController = this.application
      .getControllerForElementAndIdentifier(
        this.element.closest('[data-controller~="canva"]'),
        'canva'
      )
  }

  // Called by canva_controller when elements:changed event is received
  updateFromElements(elementData) {
    if (!elementData) return false

    let changed = false
    if (elementData.x !== undefined && elementData.x !== this.xValue) {
      this.xValue = elementData.x
      changed = true
    }
    if (elementData.y !== undefined && elementData.y !== this.yValue) {
      this.yValue = elementData.y
      changed = true
    }
    if (elementData.width !== undefined && elementData.width !== this.widthValue) {
      this.widthValue = elementData.width
      changed = true
    }
    if (elementData.height !== undefined && elementData.height !== this.heightValue) {
      this.heightValue = elementData.height
      changed = true
    }
    if (elementData.rotation !== undefined && elementData.rotation !== this.rotationValue) {
      this.rotationValue = elementData.rotation
      changed = true
    }
    // For text items, also update font_size
    if (elementData.font_size !== undefined && this.fontSizeValue !== undefined && elementData.font_size !== this.fontSizeValue) {
      this.fontSizeValue = elementData.font_size
      changed = true
    }
    return changed
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
  redraw(_event) {
    this.draw()
  }

  // --- Editor support ---

  // Hit detection: is the point inside this item's bounds?
  containsPoint(canvasX, canvasY) {
    const bounds = this.getBounds()
    return canvasX >= bounds.x &&
           canvasX <= bounds.x + bounds.width &&
           canvasY >= bounds.y &&
           canvasY <= bounds.y + bounds.height
  }

  select() {
    this.selectedValue = true
    this.dispatch("item:selected", { detail: { controller: this, name: this.nameValue } })
  }

  deselect() {
    this.selectedValue = false
    this.dispatch("item:deselected", { detail: { controller: this, name: this.nameValue } })
  }

  // Update position (called during drag)
  updatePosition(x, y) {
    this.xValue = x
    this.yValue = y
  }

  // Update size (called during resize)
  updateSize(width, height) {
    this.widthValue = width
    this.heightValue = height
  }

  // Called when item is clicked (not dragged)
  openDrawer() {
    if (this.drawerValue) {
      document.getElementById(this.drawerValue)?.showModal()
    }
  }
}
