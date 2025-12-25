import { Canvas } from "./canvas"
import { createElement } from "./elements"

// Manages front and back canvases
export class CanvasPair {
  constructor(frontCanvasEl, backCanvasEl, options = {}) {
    this.front = new Canvas(frontCanvasEl, options)
    this.back = new Canvas(backCanvasEl, options)
    this._activeSide = 'front'

    // Element instances cache (id -> element instance)
    this._elementInstances = new Map()
  }

  get activeSide() {
    return this._activeSide
  }

  // Get the active canvas
  get active() {
    return this[this._activeSide]
  }

  // Get the inactive canvas
  get inactive() {
    return this._activeSide === 'front' ? this.back : this.front
  }

  // Toggle active side
  toggle() {
    this._activeSide = this._activeSide === 'front' ? 'back' : 'front'
    return this._activeSide
  }

  // Set active side directly
  setSide(side) {
    if (side === 'front' || side === 'back') {
      this._activeSide = side
    }
    return this._activeSide
  }

  // Initialize both canvases
  init(width, height) {
    this.front.init(width, height)
    this.back.init(width, height)
  }

  // Resize both canvases
  resize(containerWidth, containerHeight, strict = false) {
    this.front.resize(containerWidth, containerHeight, strict)
    this.back.resize(containerWidth, containerHeight, strict)
  }

  // Load background images for both sides
  async loadBackgrounds(frontUrl, backUrl) {
    const promises = []
    if (frontUrl) promises.push(this.front.loadBackgroundImage(frontUrl))
    if (backUrl) promises.push(this.back.loadBackgroundImage(backUrl))
    return Promise.all(promises)
  }

  // Get or create element instance
  getElementInstance(elementData) {
    const id = elementData.id || elementData.name
    let instance = this._elementInstances.get(id)

    if (!instance) {
      instance = createElement(elementData)
      this._elementInstances.set(id, instance)
    } else {
      // Update existing instance
      instance.updateFromData(elementData)
    }

    return instance
  }

  // Remove stale element instances
  cleanupInstances(currentIds) {
    const currentIdSet = new Set(currentIds)
    for (const [id, instance] of this._elementInstances) {
      if (!currentIdSet.has(id)) {
        instance.destroy?.()
        this._elementInstances.delete(id)
      }
    }
  }

  // Render a specific side
  renderSide(side, state, selection = null, options = {}) {
    const canvas = this[side]
    if (!canvas.ctx) return

    canvas.clear()

    const elements = state.elementsForSide(side)

    // Render elements
    for (const elementData of elements) {
      const instance = this.getElementInstance(elementData)

      // Set up image load callback
      instance.onImageLoaded = () => {
        this.renderSide(side, state, selection, options)
      }

      instance.render(canvas.ctx, canvas.width, canvas.height, { debug: options.debug })
    }

    // Render selection handles only on active side
    if (side === this._activeSide && selection?.current) {
      selection.renderHandles(canvas.ctx, canvas.width, canvas.height)
    }
  }

  // Render both sides
  renderBoth(state, selection = null, options = {}) {
    this.renderSide('front', state, selection, options)
    this.renderSide('back', state, selection, options)

    // Cleanup stale instances
    const currentIds = state.elements.map(el => el.id || el.name)
    this.cleanupInstances(currentIds)
  }

  // Get element instance by ID
  getInstanceById(id) {
    return this._elementInstances.get(id)
  }

  // Destroy and cleanup
  destroy() {
    for (const instance of this._elementInstances.values()) {
      instance.destroy?.()
    }
    this._elementInstances.clear()
  }
}
