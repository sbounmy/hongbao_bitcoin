import { Controller } from "@hotwired/stimulus"

// Manages the selection overlay (border + handles) for the editor
// Simple component: show, hide, position - no pointer tracking (overlay has pointer-events-none)
export default class extends Controller {
  static targets = ["deleteBtn"]
  static values = {
    visible: { type: Boolean, default: false }
  }

  // Reference to the item we're showing overlay for
  currentItem = null

  // --- Public API (called by editor) ---

  show(item, canvasInfo) {
    if (!item) return

    this.currentItem = item
    this.visibleValue = true
    this.element.classList.remove("hidden")

    this.updatePosition(item, canvasInfo)
    this.updateDeleteButton(item)
  }

  hide() {
    this.visibleValue = false
    this.currentItem = null
    this.element.classList.add("hidden")
  }

  forceHide() {
    this.hide()
  }

  updatePosition(item, canvasInfo) {
    if (!item || !canvasInfo) return

    const bounds = item.getBounds()
    const { scaleX, scaleY } = canvasInfo

    this.element.style.left = `${bounds.x * scaleX}px`
    this.element.style.top = `${bounds.y * scaleY}px`
    this.element.style.width = `${bounds.width * scaleX}px`
    this.element.style.height = `${bounds.height * scaleY}px`

    // Apply rotation if any
    if (item.rotationValue !== 0) {
      this.element.style.transform = `rotate(${item.rotationValue}deg)`
    } else {
      this.element.style.transform = ""
    }
  }

  updateDeleteButton(item) {
    if (!this.hasDeleteBtnTarget) return

    // Hide delete button for presence items (required elements)
    this.deleteBtnTarget.classList.toggle("hidden", item?.presenceValue ?? true)
  }

  // --- Getters ---

  get isPointerOver() {
    // No longer tracking - always return false
    return false
  }

  get item() {
    return this.currentItem
  }
}
