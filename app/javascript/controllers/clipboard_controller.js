import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]
  static values = {
    successMessage: String
  }

  copy(event) {
    event.preventDefault()
    const textToCopy = this.sourceTarget.value

    navigator.clipboard.writeText(textToCopy)
      .then(() => {
        // Show success message
        const button = event.currentTarget
        const originalHTML = button.innerHTML

        // Show checkmark
        button.innerHTML = this.getCheckmarkIcon()

        // Revert back to copy icon after 1 second
        setTimeout(() => {
          button.innerHTML = originalHTML
        }, 1000)
      })
      .catch((err) => {
        console.error('Failed to copy:', err)
      })
  }

  getCheckmarkIcon() {
    return `
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
      </svg>
    `
  }
}