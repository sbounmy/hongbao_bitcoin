import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["address"]
  static values = {
    successMessage: String
  }

  copy() {
    navigator.clipboard.writeText(this.addressTarget.value.trim())
      .then(() => {
        alert(this.successMessageValue)
      })
      .catch((err) => {
        console.error('Failed to copy:', err)
      })
  }
} 