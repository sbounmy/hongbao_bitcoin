import { State } from './state'
import { CanvasPair } from './canvas_pair'
import { Selection } from './selection'
import { TouchHandler } from './touch_handler'
import { createElement } from './index'

// Editor Engine - orchestrates all editor components
// Note: Engine has NO wallet knowledge. Domain-specific data binding is handled in the controller.
export class Engine {
  constructor(frontContainerEl, backContainerEl, options = {}) {
    this.options = options

    // Core components
    this.state = new State(options.initialState || {})

    this.canvases = new CanvasPair(frontContainerEl, backContainerEl, {
      qualityScale: options.qualityScale || 3
    })

    // Selection overlays for each side
    this.selectionFront = new Selection(frontContainerEl)
    this.selectionBack = new Selection(backContainerEl)
    this.selection = this.selectionFront  // Active selection

    // Touch handlers
    this.touchFront = null
    this.touchBack = null

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
      // No backgrounds - initialize with default size
      this.canvases.front.init(1080, 1920)
      this.canvases.back.init(1080, 1920)
    }

    // Setup touch handlers on both containers
    this.bindTouchToBothCanvases()

    // Initial render
    this.render()
  }

  // Cleanup
  destroy() {
    this.touchFront?.destroy()
    this.touchBack?.destroy()
    this.selectionFront?.destroy()
    this.selectionBack?.destroy()
    this.canvases.destroy()
  }

  // Bind touch handlers to both containers
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
      this.canvases.front.el,
      createCallbacks('front')
    )

    this.touchBack = new TouchHandler(
      this.canvases.back.el,
      createCallbacks('back')
    )
  }

  // Toggle between front and back
  toggleSide() {
    this.selection.clear()
    const newSide = this.activeSide === 'front' ? 'back' : 'front'
    this.canvases.activeSide = newSide
    this.selection = newSide === 'front' ? this.selectionFront : this.selectionBack
    this.render()
    this.options.onSideChange?.(newSide)
    return newSide
  }

  // Set specific side
  setSide(side) {
    if (side !== this.activeSide) {
      this.selection.clear()
      this.canvases.activeSide = side
      this.selection = side === 'front' ? this.selectionFront : this.selectionBack
      this.render()
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

    // Render and select the new element
    this.render()
    const instance = this.canvases.getInstanceById(element.id)
    this.selection.select(element, instance)

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
      // Update DOM instance if it exists
      const instance = this.canvases.getInstanceById(id)
      if (instance) {
        instance.update(data)
      }

      // Update selection if this element is selected
      if (this.selection.isSelected(element)) {
        this.selection.select(element, instance)
      }

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
    this.render()
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
    this.render()
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
    this.render()
    this.options.onStateChange?.()

    return copy
  }

  // Load theme (replaces elements with theme defaults)
  async loadTheme(themeData) {
    const { frontUrl, backUrl, elements: allElements } = themeData

    // Load new background images
    const promises = []
    if (frontUrl) {
      promises.push(this.canvases.front.loadBackgroundImage(frontUrl))
    }
    if (backUrl) {
      promises.push(this.canvases.back.loadBackgroundImage(backUrl))
    }

    // Wait for backgrounds to load
    await Promise.all(promises)

    // Replace elements if provided
    if (allElements) {
      this.canvases.clear()  // Clear existing DOM elements
      this.state.replaceAll(allElements)
      this.selection.clear()
      this.render()
      this.options.onStateChange?.()
    }
  }

  // Get state for persistence
  getState(opts = {}) {
    return this.state.serialize(opts)
  }

  // Render - update DOM elements
  render() {
    this.canvases.renderBoth(this.state, this.selection)
  }

  // Schedule a render (immediate for DOM - no animation frame needed)
  scheduleRender() {
    this.render()
  }

  // Hit test - find element at point using DOM
  hitTest(clientX, clientY) {
    // Use elementFromPoint for DOM-based hit testing
    const el = document.elementFromPoint(clientX, clientY)

    // Find element with data-element-id
    const elementDiv = el?.closest('[data-element-id]')
    if (elementDiv) {
      const id = elementDiv.dataset.elementId
      return this.state.getElementById(id)
    }

    return null
  }

  // Touch/mouse handlers
  handleTap(point) {
    // First check if tapping a handle
    const handle = this.selection.getHandleAt(point.x, point.y)

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
  }

  handleDoubleTap(point) {
    const hit = this.hitTest(point.x, point.y)
    if (hit) {
      this.options.onElementEdit?.(hit)
    }
  }

  handleDragStart(point) {
    // Check for handle first
    const handle = this.selection.getHandleAt(point.x, point.y)
    if (handle) {
      // Settings handle doesn't drag
      if (handle === 'settings') return

      this._activeHandle = handle
      this._dragStartElement = this.selection.current ? { ...this.selection.current } : null
      return
    }

    // Check if dragging selected element
    const canvas = this.canvases.active
    const percent = canvas.clientToPercentage(point.x, point.y)

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

      // Update state and DOM
      this.updateElement(el.id || el.name, { x: el.x, y: el.y })
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
      el.rotation = (el.rotation || 0) + dxPercent
      this.updateElement(el.id || el.name, { rotation: el.rotation })
      return
    }

    // Delegate to element instance - each element type handles its own resize
    const instance = this.canvases.getInstanceById(el.id || el.name)
    if (instance) {
      const changes = instance.handleResize(handle, dxPercent, dyPercent)
      Object.assign(el, changes)
      this.updateElement(el.id || el.name, changes)
    }
  }

  handlePinchStart(_data) {
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

    // Update state and DOM
    this.updateElement(el.id || el.name, {
      width: el.width,
      height: el.height,
      rotation: el.rotation
    })
  }

  handlePinchEnd() {
    if (this._dragStartElement) {
      this.options.onStateChange?.()
    }
    this._dragStartElement = null
  }
}
