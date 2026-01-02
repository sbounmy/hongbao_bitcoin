// Base class for editor elements
// Renders as positioned div elements
export class BaseElement {
  constructor(data) {
    this.id = data.id || data.name || crypto.randomUUID()
    this.name = data.name || this.id
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

    // DOM element reference
    this.el = null
  }

  // Create the DOM element
  createElement() {
    this.el = document.createElement('div')
    this.el.className = 'editor-element hover:not-data-[selected]:ring-2 hover:not-data-[selected]:ring-primary'
    this.applyStyles()
    this.applyDataAttributes()
    this.renderContent()
    return this.el
  }

  // Ensure numeric value is valid (not NaN or Infinity)
  _safeNumber(value, fallback = 0) {
    if (typeof value !== 'number' || !Number.isFinite(value)) {
      return fallback
    }
    return value
  }

  // Apply CSS positioning using percentages
  applyStyles() {
    if (!this.el) return

    // Sanitize all numeric values before applying to CSS
    const x = this._safeNumber(this.x, 0)
    const y = this._safeNumber(this.y, 0)
    const width = this._safeNumber(this.width, 10)
    const height = this._safeNumber(this.height, 10)
    const rotation = this._safeNumber(this.rotation, 0)

    Object.assign(this.el.style, {
      position: 'absolute',
      left: `${x}%`,
      top: `${y}%`,
      width: `${width}%`,
      height: `${height}%`,
      transform: rotation ? `rotate(${rotation}deg)` : 'none',
      transformOrigin: 'center center',
      display: this.hidden ? 'none' : 'block',
      boxSizing: 'border-box',
      overflow: 'hidden',
      userSelect: 'none',        // Prevent text selection during drag
      WebkitUserDrag: 'none'     // Prevent Safari drag
    })
  }

  // Add data attributes for E2E testing
  applyDataAttributes() {
    if (!this.el) return

    this.el.dataset.elementId = this.id
    this.el.dataset.elementName = this.name
    this.el.dataset.elementType = this.type
    this.el.dataset.elementSide = this.side
    this.el.dataset.elementX = this.x
    this.el.dataset.elementY = this.y
    this.el.dataset.elementWidth = this.width
    this.el.dataset.elementHeight = this.height
  }

  // Override in subclasses to render specific content
  renderContent() {
    // Base class does nothing
  }

  // Update element from new data
  update(data) {
    if (data.x !== undefined) this.x = parseFloat(data.x)
    if (data.y !== undefined) this.y = parseFloat(data.y)
    if (data.width !== undefined) this.width = parseFloat(data.width)
    if (data.height !== undefined) this.height = parseFloat(data.height)
    if (data.rotation !== undefined) this.rotation = parseFloat(data.rotation) || 0
    if (data.hidden !== undefined) this.hidden = data.hidden
    if (data.side !== undefined) this.side = data.side

    this.applyStyles()
    this.applyDataAttributes()
    this.updateContent(data)
  }

  // Override in subclasses to update specific content
  updateContent(data) {
    // Base class does nothing
  }

  // Handle resize - override in subclasses for custom behavior
  // Returns an object with the changed properties
  handleResize(handle, dxPercent, dyPercent) {
    // Sanitize input deltas
    const dx = this._safeNumber(dxPercent, 0)
    const dy = this._safeNumber(dyPercent, 0)

    let newX = this._safeNumber(this.x, 0)
    let newY = this._safeNumber(this.y, 0)
    let newWidth = this._safeNumber(this.width, 10)
    let newHeight = this._safeNumber(this.height, 10)

    switch (handle) {
      case 'se':
        newWidth += dx
        newHeight += dy
        break
      case 'sw':
        newX += dx
        newWidth -= dx
        newHeight += dy
        break
      case 'ne':
        newWidth += dx
        newY += dy
        newHeight -= dy
        break
      case 'nw':
        newX += dx
        newY += dy
        newWidth -= dx
        newHeight -= dy
        break
      case 'e':
        newWidth += dx
        break
      case 'w':
        newX += dx
        newWidth -= dx
        break
      case 'n':
        newY += dy
        newHeight -= dy
        break
      case 's':
        newHeight += dy
        break
    }

    // Ensure minimum size and clamp to reasonable bounds
    newWidth = Math.max(2, Math.min(200, newWidth))
    newHeight = Math.max(2, Math.min(200, newHeight))
    newX = Math.max(-100, Math.min(200, newX))
    newY = Math.max(-100, Math.min(200, newY))

    this.x = newX
    this.y = newY
    this.width = newWidth
    this.height = newHeight

    return { x: newX, y: newY, width: newWidth, height: newHeight }
  }

  // Check if a point (in percentage coordinates) is within this element's bounds
  containsPoint(px, py) {
    if (this.hidden) return false
    return (
      px >= this.x &&
      px <= this.x + this.width &&
      py >= this.y &&
      py <= this.y + this.height
    )
  }

  // Cleanup
  destroy() {
    this.el?.remove()
    this.el = null
  }

  // Export current state to JSON-serializable object
  toJSON() {
    return {
      id: this.id,
      name: this.name,
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
