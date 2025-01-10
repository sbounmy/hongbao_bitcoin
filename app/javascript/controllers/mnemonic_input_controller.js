import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["word"]

  handleTab(event) {
    if (event.key === "Tab") {
      event.preventDefault()
      const currentIndex = this.wordTargets.indexOf(event.target)
      const nextIndex = currentIndex + (event.shiftKey ? -1 : 1)

      if (nextIndex >= 0 && nextIndex < this.wordTargets.length) {
        this.wordTargets[nextIndex].focus()
      }
    }
  }
}