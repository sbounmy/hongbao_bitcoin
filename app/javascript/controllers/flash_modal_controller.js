import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto close after 5 seconds for non-error messages
    const isError = this.element.querySelector('.alert-error')
    if (!isError) {
      this.autoCloseTimeout = setTimeout(() => {
        this.close()
      }, 5000)
    }
  }

  disconnect() {
    if (this.autoCloseTimeout) {
      clearTimeout(this.autoCloseTimeout)
    }
  }

  close(event) {
    if (event) event.preventDefault()
    
    // Remove modal-open class to close the modal
    this.element.classList.remove('modal-open')
    
    // Remove the element after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}