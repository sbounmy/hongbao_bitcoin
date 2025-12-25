import { Controller } from "@hotwired/stimulus"

// Displays exported canvas images from the paper-editor in the PDF preview
// Listens via data-action: paper-editor:exported@window->preview-canvas#handleExported
export default class extends Controller {
  static targets = ["front", "back"]

  handleExported(event) {
    const { front, back } = event.detail

    if (this.hasFrontTarget && front) {
      this.frontTarget.src = front
    }

    if (this.hasBackTarget && back) {
      this.backTarget.src = back
    }
  }
}
