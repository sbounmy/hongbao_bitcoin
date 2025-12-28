import { Controller } from "@hotwired/stimulus"

// Displays cloned DOM elements from the editor in the PDF preview
// Listens via data-action: editor:exported@window->preview-canvas#handleExported
export default class extends Controller {
  static targets = ["front", "back"]

  handleExported(event) {
    const { frontEl, backEl } = event.detail

    if (frontEl && this.hasFrontTarget) {
      // Style the clone to fit the preview container
      this.styleCloneForPreview(frontEl)
      this.frontTarget.replaceWith(frontEl)
      // Update target reference to the new element
      frontEl.dataset.previewCanvasTarget = 'front'
    }

    if (backEl && this.hasBackTarget) {
      this.styleCloneForPreview(backEl)
      this.backTarget.replaceWith(backEl)
      backEl.dataset.previewCanvasTarget = 'back'
    }
  }

  // Ensure cloned element fills its container properly
  styleCloneForPreview(el) {
    Object.assign(el.style, {
      width: '100%',
      height: '100%',
      position: 'relative'
    })
  }
}
