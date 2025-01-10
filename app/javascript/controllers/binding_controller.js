import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    name: String
  }

  src(event) {
    this.element.setAttribute('src', event.detail[this.nameValue])
  }

  value(event) {
    this.element.value = event.detail[this.nameValue]
  }

  html(event) {
    this.element.innerHTML = event.detail[this.nameValue]
  }
}
