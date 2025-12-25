import { Controller } from "@hotwired/stimulus"

/**
 * Storage controller - single source of truth for element positions
 *
 * Manages the hidden field containing all elements JSON.
 * Dispatches events for canva controllers to listen to.
 */
export default class extends Controller {
  static targets = ["field"]

  connect() {
    // Dispatch ready event so canva controllers can load initial data
    this.dispatch("ready", {
      detail: this.elementsBySide()
    })
  }

  /**
   * Group elements by side dynamically (like SQL GROUP BY)
   * Returns: { front: {...}, back: {...} }
   */
  elementsBySide() {
    return Object.entries(this.elements).reduce((acc, [name, data]) => {
      const side = data.side || 'default'
      acc[side] = acc[side] || {}
      acc[side][name] = data
      return acc
    }, {})
  }

  /**
   * Get all elements from the hidden field
   */
  get elements() {
    try {
      return JSON.parse(this.fieldTarget.value || '{}')
    } catch (e) {
      console.error("[Storage] Failed to parse elements:", e)
      return {}
    }
  }

  /**
   * Set all elements and dispatch change event
   */
  set elements(value) {
    this.fieldTarget.value = JSON.stringify(value)
    this.dispatch("changed", { detail: this.elementsBySide() })
  }

  /**
   * Get elements for a specific side (front or back)
   */
  elementsForSide(side) {
    return Object.fromEntries(
      Object.entries(this.elements).filter(([_, data]) => data.side === side)
    )
  }

  /**
   * Update elements for a specific side (merges with other side's elements)
   */
  updateSide(side, sideElements) {
    const all = { ...this.elements }

    // Remove old elements for this side
    Object.keys(all).forEach(key => {
      if (all[key].side === side) delete all[key]
    })

    // Add new elements with side property
    const withSide = {}
    Object.entries(sideElements).forEach(([key, data]) => {
      withSide[key] = { ...data, side }
    })

    this.elements = { ...all, ...withSide }
  }

  /**
   * Update a single element by name
   */
  updateElement(name, data) {
    const all = { ...this.elements }
    all[name] = { ...all[name], ...data }
    this.elements = all
  }

  /**
   * Remove an element by name
   */
  removeElement(name) {
    const all = { ...this.elements }
    delete all[name]
    this.elements = all
  }

  /**
   * Replace all elements (used when theme changes)
   */
  replaceAll(newElements) {
    this.elements = newElements
  }

  /**
   * Handle persist event from canva controller
   */
  handleCanvaPersist(event) {
    const { side, elements } = event.detail
    this.updateSide(side, elements)
  }
}
