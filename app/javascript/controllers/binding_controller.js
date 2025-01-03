import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    name: String,
    template: String
  }

  connect() {
    this.templateValue = this.templateValue || this.element.getAttribute('src') || this.element.value
  }

  src(event) {
    const interpolatedUrl = this.templateValue.replace(/%{([^}]+)}/g, (_, key) => {
      return event.detail[key] || `%{${key}}`
    })
    this.element.setAttribute('src', interpolatedUrl)
  }

  value(event) {
    this.element.value = event.detail[this.nameValue]
  }
}