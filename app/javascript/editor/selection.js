// Selection manager with canvas-rendered handles
export class Selection {
  constructor(options = {}) {
    this._current = null  // Currently selected element data
    this._currentInstance = null  // Element instance

    // Handle configuration
    this.handleSize = options.handleSize || 8
    this.handleColor = options.handleColor || '#f97316'  // Orange
    this.borderColor = options.borderColor || '#f97316'
    this.borderWidth = options.borderWidth || 2
    this.rotateHandleDistance = options.rotateHandleDistance || 20

    // Handle positions (set after rendering)
    this._handles = {}
  }

  get current() {
    return this._current
  }

  get currentInstance() {
    return this._currentInstance
  }

  // Select an element
  select(elementData, elementInstance = null) {
    this._current = elementData
    this._currentInstance = elementInstance
  }

  // Clear selection
  clear() {
    this._current = null
    this._currentInstance = null
    this._handles = {}
  }

  // Check if an element is selected
  isSelected(elementData) {
    if (!this._current || !elementData) return false
    return (this._current.id || this._current.name) === (elementData.id || elementData.name)
  }

  // Render selection handles on canvas
  renderHandles(ctx, canvasWidth, canvasHeight) {
    if (!this._current) return

    const el = this._current
    const bounds = {
      x: (el.x / 100) * canvasWidth,
      y: (el.y / 100) * canvasHeight,
      width: (el.width / 100) * canvasWidth,
      height: (el.height / 100) * canvasHeight
    }

    ctx.save()

    // Apply rotation if present
    if (el.rotation) {
      const centerX = bounds.x + bounds.width / 2
      const centerY = bounds.y + bounds.height / 2
      ctx.translate(centerX, centerY)
      ctx.rotate(el.rotation * Math.PI / 180)
      ctx.translate(-centerX, -centerY)
    }

    // Draw border
    ctx.strokeStyle = this.borderColor
    ctx.lineWidth = this.borderWidth
    ctx.setLineDash([])
    ctx.strokeRect(bounds.x, bounds.y, bounds.width, bounds.height)

    // Calculate handle positions
    const hs = this.handleSize
    const handles = {
      nw: { x: bounds.x - hs/2, y: bounds.y - hs/2 },
      ne: { x: bounds.x + bounds.width - hs/2, y: bounds.y - hs/2 },
      sw: { x: bounds.x - hs/2, y: bounds.y + bounds.height - hs/2 },
      se: { x: bounds.x + bounds.width - hs/2, y: bounds.y + bounds.height - hs/2 },
      n: { x: bounds.x + bounds.width/2 - hs/2, y: bounds.y - hs/2 },
      s: { x: bounds.x + bounds.width/2 - hs/2, y: bounds.y + bounds.height - hs/2 },
      w: { x: bounds.x - hs/2, y: bounds.y + bounds.height/2 - hs/2 },
      e: { x: bounds.x + bounds.width - hs/2, y: bounds.y + bounds.height/2 - hs/2 },
      rotate: {
        x: bounds.x + bounds.width/2 - hs/2,
        y: bounds.y - this.rotateHandleDistance - hs/2
      }
    }

    // Draw rotate handle line
    ctx.beginPath()
    ctx.moveTo(bounds.x + bounds.width/2, bounds.y)
    ctx.lineTo(bounds.x + bounds.width/2, bounds.y - this.rotateHandleDistance)
    ctx.stroke()

    // Draw handles
    ctx.fillStyle = this.handleColor
    Object.values(handles).forEach(h => {
      ctx.fillRect(h.x, h.y, hs, hs)
    })

    // Draw rotate handle as circle
    ctx.beginPath()
    ctx.arc(
      handles.rotate.x + hs/2,
      handles.rotate.y + hs/2,
      hs/2,
      0,
      Math.PI * 2
    )
    ctx.fill()

    // Store handles in percentage coordinates for hit testing
    this._handles = {}
    Object.entries(handles).forEach(([key, pos]) => {
      this._handles[key] = {
        x: (pos.x / canvasWidth) * 100,
        y: (pos.y / canvasHeight) * 100,
        width: (hs / canvasWidth) * 100,
        height: (hs / canvasHeight) * 100
      }
    })

    ctx.restore()
  }

  // Get handle at point (percentage coordinates)
  // Returns handle name or null
  getHandleAt(px, py) {
    const hitPadding = 1  // Extra percentage padding for easier hitting

    for (const [name, handle] of Object.entries(this._handles)) {
      if (
        px >= handle.x - hitPadding &&
        px <= handle.x + handle.width + hitPadding &&
        py >= handle.y - hitPadding &&
        py <= handle.y + handle.height + hitPadding
      ) {
        return name
      }
    }

    return null
  }

  // Get cursor style for handle
  getCursorForHandle(handleName) {
    const cursors = {
      nw: 'nwse-resize',
      ne: 'nesw-resize',
      sw: 'nesw-resize',
      se: 'nwse-resize',
      n: 'ns-resize',
      s: 'ns-resize',
      e: 'ew-resize',
      w: 'ew-resize',
      rotate: 'grab'
    }
    return cursors[handleName] || 'default'
  }

  // Check if point is inside selection bounds
  isInsideBounds(px, py) {
    if (!this._current) return false

    const el = this._current
    return (
      px >= el.x &&
      px <= el.x + el.width &&
      py >= el.y &&
      py <= el.y + el.height
    )
  }
}
