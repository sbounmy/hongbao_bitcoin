import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    document.addEventListener('keydown', this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown.bind(this))
  }

  open(event) {
    event.preventDefault()
    this.modalTarget.classList.remove('hidden')
    this.dispatch('opened')
  }

  close(event) {
    event.preventDefault()
    this.modalTarget.classList.add('hidden')
    this.dispatch('closed')
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}