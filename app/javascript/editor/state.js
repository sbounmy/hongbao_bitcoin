import { createElement } from "./index"

// State manager for editor elements
// Single source of truth for element data
export class State {
  constructor(data = {}) {
    this.canvas = data.canvas || { width: 1080, height: 1920 }
    this.sides = data.sides || {
      front: { background: null },
      back: { background: null }
    }

    // Convert elements object/array to array format
    this._elements = this._normalizeElements(data.elements || data)
  }

  // Normalize elements from various formats to array
  _normalizeElements(elements) {
    if (Array.isArray(elements)) {
      return elements.map(el => this._normalizeElement(el))
    }

    // Object format: { name: elementData }
    if (typeof elements === 'object' && elements !== null) {
      return Object.entries(elements).map(([name, data]) =>
        this._normalizeElement({
          ...data,
          id: data.id || name,
          name: name  // Keep original name for compatibility
        })
      )
    }

    return []
  }

  // Normalize a single element - ensure numeric properties are numbers
  _normalizeElement(el) {
    return {
      ...el,
      id: el.id || el.name || crypto.randomUUID(),
      // Parse numeric properties to avoid string concatenation issues
      x: parseFloat(el.x) || 0,
      y: parseFloat(el.y) || 0,
      width: parseFloat(el.width) || 10,
      height: parseFloat(el.height) || 10,
      rotation: parseFloat(el.rotation) || 0,
      font_size: el.font_size ? parseFloat(el.font_size) : undefined,
      size: el.size ? parseFloat(el.size) : undefined,
      opacity: el.opacity !== undefined ? parseFloat(el.opacity) : undefined
    }
  }

  // Get all elements
  get elements() {
    return this._elements
  }

  // Get elements for a specific side
  elementsForSide(side) {
    return this._elements.filter(el => el.side === side)
  }

  // Get element by ID
  getElementById(id) {
    return this._elements.find(el => el.id === id || el.name === id)
  }

  // Add a new element
  addElement(elementData, side) {
    const element = {
      ...elementData,
      id: elementData.id || crypto.randomUUID(),
      side: side
    }
    this._elements.push(element)
    return element
  }

  // Update an element by ID
  updateElement(id, data) {
    const element = this.getElementById(id)
    if (element) {
      Object.assign(element, data)
    }
    return element
  }

  // Remove an element by ID
  removeElement(id) {
    const index = this._elements.findIndex(el => el.id === id || el.name === id)
    if (index !== -1) {
      return this._elements.splice(index, 1)[0]
    }
    return null
  }

  // Move element to a different side
  moveToSide(id, newSide) {
    const element = this.getElementById(id)
    if (element) {
      element.side = newSide
    }
    return element
  }

  // Copy element to a different side
  copyToSide(id, newSide) {
    const element = this.getElementById(id)
    if (element) {
      const copy = {
        ...structuredClone(element),
        id: crypto.randomUUID(),
        side: newSide
      }
      this._elements.push(copy)
      return copy
    }
    return null
  }

  // Replace all elements for a side (used for theme switching)
  replaceElementsForSide(side, newElements) {
    // Remove existing elements for this side
    this._elements = this._elements.filter(el => el.side !== side)

    // Add new elements
    const normalized = this._normalizeElements(newElements)
    normalized.forEach(el => {
      el.side = side
      this._elements.push(el)
    })
  }

  // Replace all elements (full reset)
  replaceAll(newElements) {
    this._elements = this._normalizeElements(newElements)
  }

  // Serialize state for persistence
  serialize(opts = {}) {
    let elements = this._elements

    // Optionally exclude sensitive elements
    if (opts.excludeSensitive) {
      elements = elements.filter(el => !el.sensitive)
    }

    // Return in object format for Rails compatibility { name: data }
    if (opts.objectFormat) {
      const obj = {}
      elements.forEach(el => {
        const key = el.name || el.id
        obj[key] = this._serializeElement(el)
      })
      return obj
    }

    // Return as array
    return elements.map(el => this._serializeElement(el))
  }

  // Serialize a single element
  _serializeElement(el) {
    // Create element instance to use its toJSON method
    const instance = createElement(el)
    return instance.toJSON()
  }

  // Serialize for specific side (object format for Rails)
  serializeForSide(side, opts = {}) {
    const elements = this.elementsForSide(side)
    const obj = {}

    elements.forEach(el => {
      if (opts.excludeSensitive && el.sensitive) return

      const key = el.name || el.id
      const instance = createElement(el)
      obj[key] = instance.toJSON()
    })

    return obj
  }
}
