import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    orderId: Number,
    pollInterval: Number,
    shouldPoll: Boolean
  }

  connect() {
    if (this.shouldPollValue) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollTimer = setInterval(() => {
      this.fetchStatus()
    }, this.pollIntervalValue)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  async fetchStatus() {
    try {
      const response = await fetch(`/orders/${this.orderIdValue}/status.json`)
      const data = await response.json()
      
      // Update the page if status changed
      if (this.shouldUpdatePage(data)) {
        // Reload the page to show updated status
        window.location.reload()
      }
    } catch (error) {
      console.error('Error fetching order status:', error)
    }
  }

  shouldUpdatePage(data) {
    const currentStatus = this.element.dataset.currentStatus
    
    // Reload if status changed to completed or failed
    if (currentStatus !== data.state && (data.state === 'completed' || data.state === 'failed')) {
      return true
    }
    
    // Reload if status changed from pending to processing
    if (currentStatus === 'pending' && data.state === 'processing') {
      return true
    }
    
    return false
  }
}