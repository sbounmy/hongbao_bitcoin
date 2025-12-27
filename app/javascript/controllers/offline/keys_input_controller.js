import { Controller } from "@hotwired/stimulus"

// Manages the toggle between "generated" and "custom" key modes.
// - Toggles readonly attribute on inputs
// - Caches custom values when switching modes
// - Restores custom values when toggling back
// - Shows/hides regenerate button
// - Dispatches "generate" event for bitcoin_controller
export default class extends Controller {
  static targets = ["input", "regenerate"]
  static values = { mode: { type: String, default: "generated" } }

  // Initialize cache as class property (available before connect)
  customCache = {}

  connect() {
    console.log("[keys-input] connected, found inputs:", this.inputTargets.length)
    console.log("[keys-input] found regenerate buttons:", this.regenerateTargets.length)
  }

  setMode(event) {
    console.log("[keys-input] setMode called with:", event.target.value)
    this.modeValue = event.target.value
  }

  modeValueChanged() {
    // Skip if called before DOM is ready (initial value callback)
    if (!this.hasInputTarget) return

    const isCustom = this.modeValue === "custom"
    console.log("[keys-input] modeValueChanged, isCustom:", isCustom)

    if (isCustom) {
      // Switching TO custom - restore cached values
      this.inputTargets.forEach(input => {
        input.readOnly = false
        input.value = this.customCache[input.id] || ""
      })
    } else {
      // Switching TO generated - cache current values first
      this.inputTargets.forEach(input => {
        this.customCache[input.id] = input.value
        input.readOnly = true
      })
      // Trigger regenerate (bitcoin_controller listens)
      this.dispatch("generate")
    }

    this.regenerateTargets.forEach(btn => {
      btn.classList.toggle("hidden", isCustom)
    })

    // Dispatch mode change event for other controllers (e.g., fund tabs)
    this.dispatch("modeChanged", { detail: { mode: this.modeValue, isCustom } })
  }

  // Cache values as user types (in custom mode)
  cacheInput(event) {
    this.customCache[event.target.id] = event.target.value
  }
}
