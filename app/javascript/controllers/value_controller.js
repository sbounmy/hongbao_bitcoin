import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        name: String
    }

    update(event) {
		this.element.value = event.detail[this.nameValue]
    }
}
