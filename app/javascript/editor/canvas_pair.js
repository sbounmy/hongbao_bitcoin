import { Canvas } from './canvas'
import { createElement } from './index'

// Manages front and back DOM containers
export class CanvasPair {
  constructor(frontContainer, backContainer, options = {}) {
    this.front = new Canvas(frontContainer, options)
    this.back = new Canvas(backContainer, options)
    this._activeSide = 'front'

    // Cache of element instances by ID
    this._elementInstances = new Map()
  }

  get activeSide() {
    return this._activeSide
  }

  set activeSide(side) {
    this._activeSide = side
  }

  get active() {
    return this[this._activeSide]
  }

  // Load background images for both sides
  async loadBackgrounds(frontUrl, backUrl) {
    const promises = []

    if (frontUrl) {
      promises.push(this.front.loadBackgroundImage(frontUrl))
    }
    if (backUrl) {
      promises.push(this.back.loadBackgroundImage(backUrl))
    }

    await Promise.all(promises)

    // Initialize dimensions if not set from background
    if (!this.front.originalWidth) {
      this.front.init(1080, 1920)
    }
    if (!this.back.originalWidth) {
      this.back.init(1080, 1920)
    }
  }

  // Get or create element instance
  getElementInstance(elementData) {
    const id = elementData.id || elementData.name

    let instance = this._elementInstances.get(id)

    if (!instance) {
      // Create new instance
      instance = createElement(elementData)
      const el = instance.createElement()
      this._elementInstances.set(id, instance)
    } else {
      // Update existing instance
      instance.update(elementData)
    }

    return instance
  }

  // Get element instance by ID
  getInstanceById(id) {
    return this._elementInstances.get(id)
  }

  // Render elements for a specific side
  renderSide(side, state, selection = null, options = {}) {
    const canvas = this[side]
    const elements = state.elementsForSide(side)

    // Clear ALL elements from DOM (backgrounds use .editor-background, not data-element-id)
    // Recreate from JSON (single source of truth) - fixes offline mode
    canvas.el.querySelectorAll('[data-element-id]').forEach(el => el.remove())

    // Track current element IDs for this side
    const currentIds = new Set()

    // Render elements
    for (const elementData of elements) {
      const id = elementData.id || elementData.name
      currentIds.add(id)

      const instance = this.getElementInstance(elementData)

      // Set up image load callback for re-render
      instance.onImageLoaded = () => {
        // DOM handles image display automatically, but we might want to notify
      }

      // Append element to canvas if not already there
      if (!canvas.el.contains(instance.el)) {
        canvas.appendChild(instance.el)
      }
    }

    // Remove elements that are no longer on this side
    for (const [id, instance] of this._elementInstances) {
      if (instance.side === side && !currentIds.has(id)) {
        instance.destroy()
        this._elementInstances.delete(id)
      }
    }
  }

  // Render both sides
  renderBoth(state, selection = null, options = {}) {
    this.renderSide('front', state, selection, options)
    this.renderSide('back', state, selection, options)

    // Cleanup stale instances (elements that no longer exist in state)
    const allIds = new Set(state.elements.map(el => el.id || el.name))
    for (const [id, instance] of this._elementInstances) {
      if (!allIds.has(id)) {
        instance.destroy()
        this._elementInstances.delete(id)
      }
    }
  }

  // Clear all elements
  clear() {
    for (const instance of this._elementInstances.values()) {
      instance.destroy()
    }
    this._elementInstances.clear()
  }

  // Destroy and cleanup
  destroy() {
    this.clear()
  }
}
