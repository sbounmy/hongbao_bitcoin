import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    name: String,
    attribute: String,
    template: String
  }

  async #resolveValue(event) {
    const value = event.detail[this.nameValue]
    const resolved = typeof value === 'function' ? value() : value
    return resolved instanceof Promise ? await resolved : resolved
  }

  #applyTemplate(value) {
    if (!this.hasTemplateValue) return value
    
    // Replace all placeholders in the template
    // Support both {name} and {otherName} syntax
    return this.templateValue.replace(/\{([^}]+)\}/g, (match, key) => {
      // If the key matches our binding name, use the value
      if (key === this.nameValue) return value
      
      // Otherwise, check if we have that value in the event detail
      if (this.lastEventDetail && this.lastEventDetail[key]) {
        return this.lastEventDetail[key]
      }
      
      // Return the placeholder if not found
      return match
    })
  }

  async src(event) {
    this.lastEventDetail = event.detail
    const value = await this.#resolveValue(event) || ''
    const finalValue = this.#applyTemplate(value)
    this.element.setAttribute('src', finalValue)
    this.dispatch(`changed`, { detail: this.element.src })
  }

  async value(event) {
    this.lastEventDetail = event.detail
    const value = await this.#resolveValue(event)
    const finalValue = this.#applyTemplate(value)
    this.element.value = finalValue
    this.dispatch(`changed`, { detail: this.element.value })
  }

  async html(event) {
    this.lastEventDetail = event.detail
    const value = await this.#resolveValue(event)
    const finalValue = this.#applyTemplate(value)
    this.element.innerHTML = finalValue
    this.dispatch(`changed`, { detail: this.element.innerHTML })
  }

  async attribute(event) {
    this.lastEventDetail = event.detail
    const value = await this.#resolveValue(event)
    const finalValue = this.#applyTemplate(value)
    
    if (this.attributeValue === 'href') {
      this.element.setAttribute('href', finalValue)
    } else {
      this.element.dataset[this.attributeValue] = finalValue
    }
    
    this.dispatch(`changed`, { detail: finalValue })
  }
}
