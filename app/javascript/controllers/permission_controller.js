import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    types: Array
  }

  static classes = ["hidden"]

  connect() {
    this.#query()
  }

  async ask(event) {
    event.preventDefault()
    this.#request()
  }

  get #constraints() {
    return {
      name: this.typesValue[0] // Permissions must be queried individually
    }
  }

  async #query() {
    try {
      const results = await Promise.all(
        this.typesValue.map(type =>
          navigator.permissions.query({ name: type })
        )
      )

      const allGranted = results.every(permission => permission.state === 'granted')

      allGranted ?
        this.element.classList.add(this.hiddenClass) :
        this.element.classList.remove(this.hiddenClass)
    } catch (error) {
      console.error("Permission access error:", error)
    }
  }

  async #request() {
    const stream = await navigator.mediaDevices.getUserMedia(this.#constraints)
    stream.getTracks().forEach(track => track.stop())
    this.element.classList.add(this.hiddenClass)
  }
}
