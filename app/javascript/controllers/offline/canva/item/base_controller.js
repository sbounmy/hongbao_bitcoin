// Base class for all canvas items
// Items are plain JS objects (following Stimulus naming convention) that draw on a shared canvas
export default class BaseController {
  // Default drawer - subclasses override this
  static drawer = "text-edit-drawer"

  constructor(name, data, canvaController) {
    this.name = name
    this.data = data
    this.canva = canvaController
    this.type = data.type || 'text'

    // Position and size (percentages) - parse as float since theme data uses strings
    this.x = parseFloat(data.x) || 0
    this.y = parseFloat(data.y) || 0
    this.width = parseFloat(data.width) || 10
    this.height = parseFloat(data.height) || 10
    this.rotation = parseFloat(data.rotation) || 0

    // State
    this.hidden = data.hidden ?? false
    this.presence = data.presence ?? true
    this.selected = false
  }

  // Get the drawer ID for this item (from static property)
  get drawer() {
    return this.constructor.drawer
  }

  // Get canvas context
  get ctx() {
    return this.canva.ctx
  }

  // Get canvas dimensions
  get canvasWidth() {
    return this.canva.originalWidth
  }

  get canvasHeight() {
    return this.canva.originalHeight
  }

  // Convert percentage bounds to pixel coordinates
  getBounds() {
    return {
      x: (this.x / 100) * this.canvasWidth,
      y: (this.y / 100) * this.canvasHeight,
      width: (this.width / 100) * this.canvasWidth,
      height: (this.height / 100) * this.canvasHeight
    }
  }

  // Check if a point (in percentage coordinates) is within this item's bounds
  containsPoint(px, py) {
    return (
      px >= this.x &&
      px <= this.x + this.width &&
      py >= this.y &&
      py <= this.y + this.height
    )
  }

  // Update item from new element data
  updateFromData(data) {
    if (data.x !== undefined) this.x = parseFloat(data.x)
    if (data.y !== undefined) this.y = parseFloat(data.y)
    if (data.width !== undefined) this.width = parseFloat(data.width)
    if (data.height !== undefined) this.height = parseFloat(data.height)
    if (data.hidden !== undefined) this.hidden = data.hidden
    if (data.rotation !== undefined) this.rotation = parseFloat(data.rotation) || 0
  }

  // Update position (used by editor drag)
  updatePosition(x, y) {
    this.x = x
    this.y = y
  }

  // Update size (used by editor resize)
  updateSize(width, height) {
    this.width = width
    this.height = height
  }

  // Selection state (for editor)
  select() {
    this.selected = true
  }

  deselect() {
    this.selected = false
  }

  // Open the associated drawer
  openDrawer() {
    const drawer = document.getElementById(this.drawer)
    if (drawer) {
      drawer.showModal()
    }
  }

  // Draw the item on canvas - override in subclasses
  draw() {
    // Base class does nothing
  }

  // Cleanup - override in subclasses if needed
  destroy() {
    // Base class does nothing
  }

  // Export current state to JSON-serializable object
  toJSON() {
    return {
      type: this.type,
      x: this.x,
      y: this.y,
      width: this.width,
      height: this.height,
      rotation: this.rotation,
      hidden: this.hidden,
      presence: this.presence
    }
  }
}
