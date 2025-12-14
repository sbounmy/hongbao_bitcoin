import { Controller } from "@hotwired/stimulus"

// Animates a progress bar over a specified duration (default 60 seconds)
// Usage: data-controller="progress" data-progress-duration-value="60"
export default class extends Controller {
  static values = {
    duration: { type: Number, default: 60 } // seconds
  }
  static targets = ["bar"]

  connect() {
    this.animate()
  }

  animate() {
    // Use CSS transition for smooth animation
    const durationMs = this.durationValue * 1000

    // Set transition on the bar
    this.barTarget.style.transition = `width ${durationMs}ms linear`

    // Trigger animation on next frame
    requestAnimationFrame(() => {
      this.barTarget.style.width = '100%'
    })
  }
}
