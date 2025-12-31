import { Controller } from "@hotwired/stimulus"

// Displays cloned DOM elements from the editor in the PDF preview
// Listens via data-action: editor:exported@window->editor--preview-canvas#handleExported
export default class extends Controller {
  static targets = ["front", "back", "layoutContainer"]

  handleExported(event) {
    const { frontEl, backEl, layoutDirection } = event.detail

    // Update layout direction if provided (for orientation switch)
    if (layoutDirection && this.hasLayoutContainerTarget) {
      const cuttableDiv = this.layoutContainerTarget.firstElementChild
      if (cuttableDiv) {
        cuttableDiv.classList.remove('flex-row', 'flex-col', 'overflow-x-auto', 'overflow-y-auto')
        layoutDirection.split(' ').forEach(cls => cuttableDiv.classList.add(cls))
      }
    }

    if (frontEl && this.hasFrontTarget) {
      // Style the clone to fit the preview container
      this.styleCloneForPreview(frontEl)
      this.frontTarget.replaceWith(frontEl)
      // Update target reference to the new element
      frontEl.setAttribute('data-editor--preview-canvas-target', 'front')
    }

    if (backEl && this.hasBackTarget) {
      this.styleCloneForPreview(backEl)
      this.backTarget.replaceWith(backEl)
      backEl.setAttribute('data-editor--preview-canvas-target', 'back')
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
