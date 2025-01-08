import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    types: Array
  }

  static classes = ["hidden"]

  async ask(event) {
    event.preventDefault()
    this.#request()
  }

  get #constraints() {
    return this.typesValue.reduce((acc, type) => {
      acc[type] = true
      return acc
    }, {})
  }

  async #request() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia(this.#constraints)
      stream.getTracks().forEach(track => track.stop())
      this.element.classList.add(this.hiddenClass)
    } catch (error) {
      console.error("Permission access error:", error)
    }
  }
}