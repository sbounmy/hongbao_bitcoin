import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    remove(event) {
        this.element.disabled = false
    }

    add(event) {
        this.element.disabled = true
    }
}

