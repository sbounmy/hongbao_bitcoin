import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    successMessage: String,
    address: String
  }

  copy(event) {
    event.preventDefault()
    navigator.clipboard.writeText(this.addressValue)
      .then(() => {
        alert(this.successMessageValue)

      })
      .catch((err) => {
        console.error('Failed to copy:', err)
      })
  }
}