// Selection manager with DOM-rendered handles
// Renders selection as an overlay div with handle divs
export class DOMSelection {
  constructor(container, options = {}) {
    this.container = container
    this._current = null  // Currently selected element data
    this._currentInstance = null  // DOM element instance

    // Handle configuration
    this.handleSize = options.handleSize || 10
    this.handleColor = options.handleColor || '#f97316'  // Orange
    this.borderColor = options.borderColor || '#f97316'
    this.borderWidth = options.borderWidth || 2
    this.rotateHandleDistance = options.rotateHandleDistance || 25

    // Create overlay and handles
    this.overlay = this.createOverlay()
    this.handles = this.createHandles()

    // Initially hidden
    this.hide()
  }

  get current() {
    return this._current
  }

  get currentInstance() {
    return this._currentInstance
  }

  createOverlay() {
    const overlay = document.createElement('div')
    overlay.className = 'editor-selection-overlay'
    Object.assign(overlay.style, {
      position: 'absolute',
      border: `${this.borderWidth}px solid ${this.borderColor}`,
      pointerEvents: 'none',
      boxSizing: 'border-box',
      zIndex: '1000'
    })
    this.container.appendChild(overlay)
    return overlay
  }

  createHandles() {
    const positions = ['nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w', 'rotate', 'settings']
    const handles = {}

    positions.forEach(pos => {
      const handle = document.createElement('div')
      handle.className = `editor-handle editor-handle-${pos}`
      handle.dataset.handle = pos
      Object.assign(handle.style, {
        position: 'absolute',
        width: `${this.handleSize}px`,
        height: `${this.handleSize}px`,
        background: this.handleColor,
        cursor: this.getCursorForHandle(pos),
        pointerEvents: 'auto',
        zIndex: '1001',
        boxSizing: 'border-box'
      })

      // Special styling for rotate handle (circle)
      if (pos === 'rotate') {
        Object.assign(handle.style, {
          borderRadius: '50%'
        })
      }

      // Special styling for settings handle (gear icon)
      if (pos === 'settings') {
        Object.assign(handle.style, {
          borderRadius: '50%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: `${this.handleSize}px`,
          color: '#fff'
        })
        handle.textContent = '\u2699'
      }

      this.overlay.appendChild(handle)
      handles[pos] = handle
    })

    // Create rotate handle line
    this.rotateLine = document.createElement('div')
    this.rotateLine.className = 'editor-rotate-line'
    Object.assign(this.rotateLine.style, {
      position: 'absolute',
      width: '2px',
      height: `${this.rotateHandleDistance}px`,
      background: this.borderColor,
      left: '50%',
      transform: 'translateX(-50%)',
      top: `-${this.rotateHandleDistance}px`,
      pointerEvents: 'none'
    })
    this.overlay.appendChild(this.rotateLine)

    return handles
  }

  // Select an element
  select(elementData, elementInstance = null) {
    this._current = elementData
    this._currentInstance = elementInstance
    this.updatePosition()
    this.show()
  }

  // Clear selection
  clear() {
    this._current = null
    this._currentInstance = null
    this.hide()
  }

  // Check if an element is selected
  isSelected(elementData) {
    if (!this._current || !elementData) return false
    return (this._current.id || this._current.name) === (elementData.id || elementData.name)
  }

  // Update overlay position based on selected element
  updatePosition() {
    if (!this._current) return

    const el = this._current

    Object.assign(this.overlay.style, {
      left: `${el.x}%`,
      top: `${el.y}%`,
      width: `${el.width}%`,
      height: `${el.height}%`,
      transform: el.rotation ? `rotate(${el.rotation}deg)` : 'none',
      transformOrigin: 'center center'
    })

    this.positionHandles()
  }

  positionHandles() {
    const hs = this.handleSize
    const half = hs / 2

    // Corner handles
    Object.assign(this.handles.nw.style, {
      left: `-${half}px`,
      top: `-${half}px`
    })
    Object.assign(this.handles.ne.style, {
      right: `-${half}px`,
      top: `-${half}px`,
      left: 'auto'
    })
    Object.assign(this.handles.sw.style, {
      left: `-${half}px`,
      bottom: `-${half}px`,
      top: 'auto'
    })
    Object.assign(this.handles.se.style, {
      right: `-${half}px`,
      bottom: `-${half}px`,
      top: 'auto',
      left: 'auto'
    })

    // Edge handles
    Object.assign(this.handles.n.style, {
      left: `calc(50% - ${half}px)`,
      top: `-${half}px`
    })
    Object.assign(this.handles.s.style, {
      left: `calc(50% - ${half}px)`,
      bottom: `-${half}px`,
      top: 'auto'
    })
    Object.assign(this.handles.w.style, {
      left: `-${half}px`,
      top: `calc(50% - ${half}px)`
    })
    Object.assign(this.handles.e.style, {
      right: `-${half}px`,
      top: `calc(50% - ${half}px)`,
      left: 'auto'
    })

    // Rotate handle (above center)
    Object.assign(this.handles.rotate.style, {
      left: `calc(50% - ${half}px)`,
      top: `-${this.rotateHandleDistance + half}px`
    })

    // Settings handle (top-right outside)
    Object.assign(this.handles.settings.style, {
      right: `-${hs + 5}px`,
      top: `-${half}px`,
      left: 'auto'
    })
  }

  show() {
    this.overlay.style.display = 'block'
  }

  hide() {
    this.overlay.style.display = 'none'
  }

  // Get handle at point using elementFromPoint
  getHandleAt(clientX, clientY) {
    const el = document.elementFromPoint(clientX, clientY)
    return el?.dataset?.handle || null
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
      rotate: 'grab',
      settings: 'pointer'
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

  // Destroy overlay
  destroy() {
    this.overlay.remove()
  }
}
