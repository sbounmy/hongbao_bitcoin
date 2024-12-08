import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    // Add transition classes
    this.element.classList.add('transition-opacity', 'duration-300', 'opacity-0')

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}