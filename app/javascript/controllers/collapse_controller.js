import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapse"
export default class extends Controller {
  static values = {
    id: String,
    open: Boolean
  }

  connect() {
    const storedState = this.storage.getItem(this.storageKey)
    let initialState = this.openValue

    if (storedState !== null) {
      initialState = storedState === "true"
    }

    if (initialState) {
      this.element.classList.add("collapse-open")
    }

    if (storedState === null) {
      this.storage.setItem(this.storageKey, initialState)
    }
  }

  toggle() {
    this.element.classList.toggle("collapse-open")
    const newState = this.element.classList.contains("collapse-open")
    this.storage.setItem(this.storageKey, newState)
  }

  get storage() {
    return window.localStorage
  }

  get storageKey() {
    return `collapse-${this.idValue}`
  }
}