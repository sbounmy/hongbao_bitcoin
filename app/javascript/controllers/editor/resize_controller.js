import { Controller } from "@hotwired/stimulus"

// Handles resize interactions via corner handles
// Dispatches events for the editor to coordinate with canvas
export default class extends Controller {
  static values = {
    active: { type: Boolean, default: false }
  }

  // Resize state
  handle = null
  startData = null

  start(e) {
    const handle = e.currentTarget.dataset.handle
    if (!handle) return

    this.activeValue = true
    this.handle = handle

    // Get item from editor via event
    const detail = { handle, clientX: e.clientX, clientY: e.clientY }
    this.dispatch("start", { detail, bubbles: true })

    // Store start position
    this.startX = e.clientX
    this.startY = e.clientY

    // Setup document listeners
    this.boundOnMove = this.onMove.bind(this)
    this.boundOnEnd = this.onEnd.bind(this)
    document.addEventListener("pointermove", this.boundOnMove)
    document.addEventListener("pointerup", this.boundOnEnd)

    e.preventDefault()
    e.stopPropagation()
  }

  onMove(e) {
    if (!this.activeValue) return

    const dx = e.clientX - this.startX
    const dy = e.clientY - this.startY

    this.dispatch("move", {
      detail: { handle: this.handle, dx, dy, clientX: e.clientX, clientY: e.clientY },
      bubbles: true
    })
  }

  onEnd(e) {
    if (!this.activeValue) return

    this.activeValue = false
    this.handle = null

    document.removeEventListener("pointermove", this.boundOnMove)
    document.removeEventListener("pointerup", this.boundOnEnd)

    this.dispatch("end", { detail: { pointerType: e.pointerType }, bubbles: true })
  }

  get isActive() {
    return this.activeValue
  }
}
