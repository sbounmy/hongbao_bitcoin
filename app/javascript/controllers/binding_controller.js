import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    name: String,
    attribute: String
  }

  async #resolveValue(event) {
    const value = event.detail[this.nameValue]
    const resolved = typeof value === 'function' ? value() : value
    return resolved instanceof Promise ? await resolved : resolved
  }

  async src(event) {
    this.element.setAttribute('src', await this.#resolveValue(event) || '')
    this.dispatch(`changed`, { detail: this.element.src })
  }

  async value(event) {
    this.element.value = await this.#resolveValue(event)
    this.dispatch(`changed`, { detail: this.element.value })
  }

  async html(event) {
    this.element.innerHTML = await this.#resolveValue(event)
    this.dispatch(`changed`, { detail: this.element.innerHTML })
  }

  async attribute(event) {
    this.element.dataset[this.attributeValue] = await this.#resolveValue(event)
    this.dispatch(`changed`, { detail: this.element.dataset[this.attributeValue] })
  }
}
