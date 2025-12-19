import { Controller } from "@hotwired/stimulus"

// Handles portrait display, loading states, and AI generation updates
// Reusable across different views (papers/new2, papers/show, etc.)
export default class extends Controller {
  static targets = ["loading", "success"]
  static values = {
    loading: Boolean  // Whether AI generation is in progress
  }

  connect() {
    // Listen for AI portrait generation events
    this.handleLoading = this.handleLoading.bind(this)
    this.handleGenerated = this.handleGenerated.bind(this)

    window.addEventListener("portrait:loading", this.handleLoading)
    window.addEventListener("portrait:generated", this.handleGenerated)
  }

  disconnect() {
    window.removeEventListener("portrait:loading", this.handleLoading)
    window.removeEventListener("portrait:generated", this.handleGenerated)
  }

  // Handle loading event - show loading indicator
  handleLoading(event) {
    this.loadingValue = true
    this.showLoading()
  }

  // Handle AI-generated portrait from Turbo Stream broadcast
  handleGenerated(event) {
    const url = event.detail?.url
    if (url) {
      this.loadingValue = false
      this.hideLoading()
      this.dispatchPortraitChanged(url)
      this.showSuccessNotification()
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }

  // Dispatch event for canvas to redraw with new portrait
  dispatchPortraitChanged(url) {
    window.dispatchEvent(new CustomEvent("portrait:changed", {
      detail: { url }
    }))
  }

  showSuccessNotification() {
    if (this.hasSuccessTarget) {
      this.successTarget.classList.remove("hidden")
      setTimeout(() => {
        this.successTarget.classList.add("hidden")
      }, 3000)
    }
  }
}
