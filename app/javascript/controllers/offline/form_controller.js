import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["errorMessage", "submitButton"]

  error(event) {
    const { message } = event.detail
    this.errorMessageTarget.querySelector('span').textContent = message
    this.errorMessageTarget.classList.remove('hidden')
    this.submitButtonTarget.disabled = true
  }

  success(event) {
    this.errorMessageTarget.querySelector('span').textContent = ''
    this.errorMessageTarget.classList.add('hidden')
    this.submitButtonTarget.disabled = false
  }
}
