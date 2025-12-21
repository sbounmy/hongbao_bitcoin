import { Controller } from "@hotwired/stimulus"

// Handles rotation interactions via the rotation handle
// Dispatches events for the editor to coordinate with canvas
export default class extends Controller {
  static values = {
    active: { type: Boolean, default: false }
  }

  // Rotation state
  center = null
  startRotation = 0

  start(e) {
    this.activeValue = true

    // Request center point from editor
    this.dispatch("start", {
      detail: { clientX: e.clientX, clientY: e.clientY },
      bubbles: true
    })

    // Setup document listeners
    this.boundOnMove = this.onMove.bind(this)
    this.boundOnEnd = this.onEnd.bind(this)
    document.addEventListener("pointermove", this.boundOnMove)
    document.addEventListener("pointerup", this.boundOnEnd)

    e.preventDefault()
    e.stopPropagation()
  }

  // Called by editor to set center point
  setCenter(center, startRotation) {
    this.center = center
    this.startRotation = startRotation
  }

  onMove(e) {
    if (!this.activeValue || !this.center) return

    const angle = Math.atan2(
      e.clientY - this.center.y,
      e.clientX - this.center.x
    ) * 180 / Math.PI

    // Offset by 90 degrees since handle is at top
    const rotation = angle + 90

    this.dispatch("move", {
      detail: { rotation },
      bubbles: true
    })
  }

  onEnd(e) {
    if (!this.activeValue) return

    this.activeValue = false
    this.center = null

    document.removeEventListener("pointermove", this.boundOnMove)
    document.removeEventListener("pointerup", this.boundOnEnd)

    this.dispatch("end", { detail: { pointerType: e.pointerType }, bubbles: true })
  }

  get isActive() {
    return this.activeValue
  }
}
