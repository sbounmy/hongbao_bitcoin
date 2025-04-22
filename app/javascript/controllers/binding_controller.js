import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    name: String
  }

  async #resolveValue(event) {
    const value = event.detail[this.nameValue]
    const resolved = typeof value === 'function' ? value() : value
    return resolved instanceof Promise ? await resolved : resolved
  }

  async src(event) {
    this.element.setAttribute('src', await this.#resolveValue(event))
  }

  async value(event) {
    this.element.value = await this.#resolveValue(event)
  }

  async html(event) {
    this.element.innerHTML = await this.#resolveValue(event)
  }
}
