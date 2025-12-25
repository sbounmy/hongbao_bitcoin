// Base class for all canvas elements
// Elements are plain JS objects that draw on a shared canvas
export class BaseElement {
  constructor(data) {
    this.id = data.id || data.name || crypto.randomUUID()
    this.type = data.type || 'unknown'
    this.side = data.side || 'front'

    // Position and size (percentages 0-100)
    this.x = parseFloat(data.x) || 0
    this.y = parseFloat(data.y) || 0
    this.width = parseFloat(data.width) || 10
    this.height = parseFloat(data.height) || 10
    this.rotation = parseFloat(data.rotation) || 0

    // State
    this.hidden = data.hidden ?? false
    this.presence = data.presence ?? true  // Cannot delete if true
    this.sensitive = data.sensitive ?? false  // Strip from server save if true
  }

  // Convert percentage bounds to pixel coordinates
  getBounds(canvasWidth, canvasHeight) {
    return {
      x: (this.x / 100) * canvasWidth,
      y: (this.y / 100) * canvasHeight,
      width: (this.width / 100) * canvasWidth,
      height: (this.height / 100) * canvasHeight
    }
  }

  // Check if a point (in percentage coordinates) is within this element's bounds
  // TODO: Handle rotation for accurate hit testing
  containsPoint(px, py) {
    if (this.hidden) return false
    return (
      px >= this.x &&
      px <= this.x + this.width &&
      py >= this.y &&
      py <= this.y + this.height
    )
  }

  // Update element from new data
  updateFromData(data) {
    if (data.x !== undefined) this.x = parseFloat(data.x)
    if (data.y !== undefined) this.y = parseFloat(data.y)
    if (data.width !== undefined) this.width = parseFloat(data.width)
    if (data.height !== undefined) this.height = parseFloat(data.height)
    if (data.rotation !== undefined) this.rotation = parseFloat(data.rotation) || 0
    if (data.hidden !== undefined) this.hidden = data.hidden
    if (data.side !== undefined) this.side = data.side
  }

  // Update position (used by drag)
  updatePosition(x, y) {
    this.x = x
    this.y = y
  }

  // Update size (used by resize)
  updateSize(width, height) {
    this.width = width
    this.height = height
  }

  // Render with rotation transform applied
  render(ctx, canvasWidth, canvasHeight, options = {}) {
    if (this.hidden) return

    const bounds = this.getBounds(canvasWidth, canvasHeight)

    ctx.save()

    // Apply rotation around element center
    if (this.rotation !== 0) {
      const centerX = bounds.x + bounds.width / 2
      const centerY = bounds.y + bounds.height / 2
      ctx.translate(centerX, centerY)
      ctx.rotate(this.rotation * Math.PI / 180)
      ctx.translate(-centerX, -centerY)
    }

    this.draw(ctx, bounds, canvasWidth, canvasHeight)

    ctx.restore()
  }

  // Draw the element - override in subclasses
  draw(ctx, bounds, canvasWidth, canvasHeight) {
    // Base class does nothing
  }

  // Cleanup - override in subclasses if needed
  destroy() {
    // Base class does nothing
  }

  // Export current state to JSON-serializable object
  toJSON() {
    return {
      id: this.id,
      type: this.type,
      side: this.side,
      x: this.x,
      y: this.y,
      width: this.width,
      height: this.height,
      rotation: this.rotation,
      hidden: this.hidden,
      presence: this.presence,
      sensitive: this.sensitive
    }
  }
}
