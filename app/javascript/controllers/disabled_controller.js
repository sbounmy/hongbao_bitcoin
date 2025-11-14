import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['element']

    remove(event) {
        // Support both target-based and direct controller usage
        const element = this.hasElementTarget ? this.elementTarget : this.element
        element.disabled = false
    }

    add(event) {
        // Support both target-based and direct controller usage
        const element = this.hasElementTarget ? this.elementTarget : this.element
        element.disabled = true
    }
}

