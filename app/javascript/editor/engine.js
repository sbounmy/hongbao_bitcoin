import { State } from "./state"
import { CanvasPair } from "./canvas_pair"
import { Selection } from "./selection"
import { TouchHandler } from "./touch_handler"
import { createElement } from "./elements"

// Editor engine - orchestrates all editor components
// Note: Engine has NO wallet knowledge. Domain-specific data binding is handled in the controller.
export class Engine {
  constructor(frontCanvasEl, backCanvasEl, options = {}) {
    this.options = options

    // Core components
    this.state = new State(options.initialState || {})

    this.canvases = new CanvasPair(frontCanvasEl, backCanvasEl, {
      qualityScale: options.qualityScale || 3
    })
    this.selection = new Selection()

    // Touch handler - attached to active canvas
    this.touch = null

    // Animation frame ID
    this._rafId = null
    this._needsRender = true

    // Interaction state
    this._activeHandle = null
    this._dragStartElement = null
  }

  get activeSide() {
    return this.canvases.activeSide
  }

  // Initialize and start the engine
  async start() {
    // Load background images if provided
    const { frontBackground, backBackground } = this.options

    if (frontBackground || backBackground) {
      try {
        await this.canvases.loadBackgrounds(frontBackground, backBackground)
      } catch (err) {
        console.error('[Engine] failed to load backgrounds:', err)
      }
    } else {
      // No backgrounds - initialize canvases with default size
      this.canvases.init(1080, 1920) // Default wallet size
    }

    // Setup touch handlers on BOTH canvas wrappers
    this.bindTouchToBothCanvases()

    // Start render loop
    this.render()
  }

  // Cleanup
  destroy() {
    if (this._rafId) {
      cancelAnimationFrame(this._rafId)
      this._rafId = null
    }

    this.touchFront?.destroy()
    this.touchBack?.destroy()
    this.canvases.destroy()
  }

  // Bind touch handlers to both canvas wrappers
  bindTouchToBothCanvases() {
    this.touchFront?.destroy()
    this.touchBack?.destroy()

    const createCallbacks = (side) => ({
      onTap: (point) => { this.setSide(side); this.handleTap(point) },
      onDoubleTap: (point) => { this.setSide(side); this.handleDoubleTap(point) },
      onDragStart: (point) => { this.setSide(side); this.handleDragStart(point) },
      onDrag: (data) => this.handleDrag(data),
      onDragEnd: (point) => this.handleDragEnd(point),
      onHover: (point) => this.handleHover(point),
      onPinchStart: (data) => { this.setSide(side); this.handlePinchStart(data) },
      onPinch: (data) => this.handlePinch(data),
      onPinchEnd: () => this.handlePinchEnd()
    })

    this.touchFront = new TouchHandler(
      this.canvases.front.el.parentElement,
      createCallbacks('front')
    )

    this.touchBack = new TouchHandler(
      this.canvases.back.el.parentElement,
      createCallbacks('back')
    )
  }

  // Toggle between front and back
  toggleSide() {
    this.selection.clear()
    const newSide = this.canvases.toggle()
    this.scheduleRender()
    this.options.onSideChange?.(newSide)
    return newSide
  }

  // Set specific side
  setSide(side) {
    if (side !== this.activeSide) {
      this.selection.clear()
      this.canvases.setSide(side)
      this.scheduleRender()
      this.options.onSideChange?.(side)
    }
    return this.activeSide
  }

  // Add new element
  addElement(type, customData = {}) {
    const defaults = this.getDefaultsForType(type)
    const elementData = {
      ...defaults,
      ...customData,
      id: crypto.randomUUID(),
      type,
      side: this.activeSide
    }

    const element = this.state.addElement(elementData, this.activeSide)

    // Select the new element
    const instance = this.canvases.getElementInstance(element)
    this.selection.select(element, instance)

    this.scheduleRender()
    this.options.onStateChange?.()
    this.options.onSelectionChange?.(element)

    return element
  }

  // Get default values for element type
  getDefaultsForType(type) {
    const defaults = {
      text: {
        x: 10,
        y: 50,
        width: 30,
        height: 10,
        text: "New Text",
        font_size: 3,
        font_color: "#000000",
        presence: false
      },
      image: {
        x: 30,
        y: 20,
        width: 20,
        height: 30,
        presence: false
      }
    }
    return defaults[type] || defaults.text
  }

  // Update element by ID
  updateElement(id, data) {
    const element = this.state.updateElement(id, data)
    if (element) {
      // Update instance if it exists
      const instance = this.canvases.getInstanceById(id)
      if (instance) {
        instance.updateFromData(data)
      }

      // Update selection if this element is selected
      if (this.selection.isSelected(element)) {
        this.selection.select(element, instance)
      }

      this.scheduleRender()
      this.options.onStateChange?.()
    }
    return element
  }

  // Delete selected element
  deleteSelected() {
    const selected = this.selection.current
    if (!selected) return false

    // Don't delete presence elements
    if (selected.presence) {
      return false
    }

    this.state.removeElement(selected.id || selected.name)
    this.selection.clear()
    this.scheduleRender()
    this.options.onStateChange?.()
    this.options.onSelectionChange?.(null)

    return true
  }

  // Move selected element to other side
  moveSelectedToOtherSide() {
    const selected = this.selection.current
    if (!selected) return null

    const newSide = this.activeSide === 'front' ? 'back' : 'front'
    this.state.moveToSide(selected.id || selected.name, newSide)
    this.selection.clear()
    this.scheduleRender()
    this.options.onStateChange?.()
    this.options.onSelectionChange?.(null)

    return newSide
  }

  // Copy selected element to other side
  copySelectedToOtherSide() {
    const selected = this.selection.current
    if (!selected) return null

    const newSide = this.activeSide === 'front' ? 'back' : 'front'
    const copy = this.state.copyToSide(selected.id || selected.name, newSide)
    this.scheduleRender()
    this.options.onStateChange?.()

    return copy
  }

  // Load theme (replaces elements with theme defaults)
  loadTheme(themeData) {
    const { frontUrl, backUrl, elements: allElements } = themeData

    // Load new background images
    if (frontUrl) {
      this.canvases.front.loadBackgroundImage(frontUrl).then(() => {
        this.scheduleRender()
      })
    }
    if (backUrl) {
      this.canvases.back.loadBackgroundImage(backUrl).then(() => {
        this.scheduleRender()
      })
    }

    // Replace elements if provided
    if (allElements) {
      this.state.replaceAll(allElements)
      this.selection.clear()
      this.scheduleRender()
      this.options.onStateChange?.()
    }
  }

  // Get state for persistence
  getState(opts = {}) {
    return this.state.serialize(opts)
  }

  // Schedule a render
  scheduleRender() {
    this._needsRender = true
  }

  // Render loop
  render() {
    if (this._needsRender) {
      // Enable debug mode to visualize element bounds
      this.canvases.renderBoth(this.state, this.selection, { debug: this._debug })
      this._needsRender = false
    }

    this._rafId = requestAnimationFrame(() => this.render())
  }

  // Toggle debug mode
  setDebug(enabled) {
    this._debug = enabled
    this.scheduleRender()
  }

  // Hit test - find element at point
  hitTest(clientX, clientY) {
    const canvas = this.canvases.active
    const percent = canvas.clientToPercentage(clientX, clientY)

    const elements = this.state.elementsForSide(this.activeSide)

    // Reverse order - top elements first
    for (let i = elements.length - 1; i >= 0; i--) {
      const el = elements[i]
      const instance = createElement(el)
      if (instance.containsPoint(percent.x, percent.y)) {
        return el
      }
    }

    return null
  }

  // Touch/mouse handlers
  handleTap(point) {
    // First check if tapping a handle
    const canvas = this.canvases.active
    const percent = canvas.clientToPercentage(point.x, point.y)
    const handle = this.selection.getHandleAt(percent.x, percent.y)

    if (handle) {
      // Settings handle opens element drawer
      if (handle === 'settings' && this.selection.current) {
        this.options.onElementEdit?.(this.selection.current)
        return
      }
      this._activeHandle = handle
      return
    }

    // Hit test for elements
    const hit = this.hitTest(point.x, point.y)

    if (hit) {
      const instance = this.canvases.getInstanceById(hit.id || hit.name)
      this.selection.select(hit, instance)
      this.options.onSelectionChange?.(hit)
    } else {
      this.selection.clear()
      this.options.onSelectionChange?.(null)
    }

    this.scheduleRender()
  }

  handleDoubleTap(point) {
    const hit = this.hitTest(point.x, point.y)
    if (hit) {
      this.options.onElementEdit?.(hit)
    }
  }

  handleDragStart(point) {
    const canvas = this.canvases.active
    const percent = canvas.clientToPercentage(point.x, point.y)

    // Check for handle
    const handle = this.selection.getHandleAt(percent.x, percent.y)
    if (handle) {
      // Settings handle doesn't drag
      if (handle === 'settings') return

      this._activeHandle = handle
      this._dragStartElement = this.selection.current ? { ...this.selection.current } : null
      return
    }

    // Check for element
    if (this.selection.current && this.selection.isInsideBounds(percent.x, percent.y)) {
      this._dragStartElement = { ...this.selection.current }
    } else {
      this._dragStartElement = null
    }
  }

  handleDrag(data) {
    if (!this.selection.current) return

    const canvas = this.canvases.active

    // Convert delta to percentage
    const rect = canvas.getBoundingRect()
    const dxPercent = (data.dx / rect.width) * 100
    const dyPercent = (data.dy / rect.height) * 100

    if (this._activeHandle) {
      this.handleResize(this._activeHandle, dxPercent, dyPercent)
    } else if (this._dragStartElement) {
      // Move element
      const el = this.selection.current
      el.x += dxPercent
      el.y += dyPercent

      // Update state
      this.state.updateElement(el.id || el.name, { x: el.x, y: el.y })
      this.scheduleRender()
    }
  }

  handleDragEnd() {
    if (this._dragStartElement || this._activeHandle) {
      this.options.onStateChange?.()
    }
    this._activeHandle = null
    this._dragStartElement = null
  }

  handleHover() {
    // Could be used for hover effects
  }

  handleResize(handle, dxPercent, dyPercent) {
    const el = this.selection.current
    if (!el) return

    // Handle rotation separately
    if (handle === 'rotate') {
      // Simplified rotation - adjust based on horizontal drag
      el.rotation = (el.rotation || 0) + dxPercent
      this.state.updateElement(el.id || el.name, { rotation: el.rotation })
      this.scheduleRender()
      return
    }

    // Resize based on handle
    let newX = el.x
    let newY = el.y
    let newWidth = el.width
    let newHeight = el.height

    switch (handle) {
      case 'se':
        newWidth += dxPercent
        newHeight += dyPercent
        break
      case 'sw':
        newX += dxPercent
        newWidth -= dxPercent
        newHeight += dyPercent
        break
      case 'ne':
        newWidth += dxPercent
        newY += dyPercent
        newHeight -= dyPercent
        break
      case 'nw':
        newX += dxPercent
        newY += dyPercent
        newWidth -= dxPercent
        newHeight -= dyPercent
        break
      case 'e':
        newWidth += dxPercent
        break
      case 'w':
        newX += dxPercent
        newWidth -= dxPercent
        break
      case 'n':
        newY += dyPercent
        newHeight -= dyPercent
        break
      case 's':
        newHeight += dyPercent
        break
    }

    // Ensure minimum size
    if (newWidth < 2) newWidth = 2
    if (newHeight < 2) newHeight = 2

    // Update element
    el.x = newX
    el.y = newY
    el.width = newWidth
    el.height = newHeight

    this.state.updateElement(el.id || el.name, {
      x: newX,
      y: newY,
      width: newWidth,
      height: newHeight
    })

    this.scheduleRender()
  }

  handlePinchStart(_data) {
    // Store initial element state for pinch
    if (this.selection.current) {
      this._dragStartElement = { ...this.selection.current }
    }
  }

  handlePinch(pinchData) {
    const el = this.selection.current
    if (!el || !this._dragStartElement) return

    const startEl = this._dragStartElement

    // Apply scale to width/height
    el.width = startEl.width * pinchData.scale
    el.height = startEl.height * pinchData.scale

    // Apply rotation
    el.rotation = (startEl.rotation || 0) + pinchData.rotation

    // Update state
    this.state.updateElement(el.id || el.name, {
      width: el.width,
      height: el.height,
      rotation: el.rotation
    })

    this.scheduleRender()
  }

  handlePinchEnd() {
    if (this._dragStartElement) {
      this.options.onStateChange?.()
    }
    this._dragStartElement = null
  }
}
