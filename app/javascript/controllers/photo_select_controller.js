import { Controller } from "@hotwired/stimulus"

// Handles selecting a previously uploaded photo to reuse
export default class extends Controller {
  static targets = ["preview", "placeholder", "blobId", "input", "previewThumb"]

  select(event) {
    event.preventDefault()
    const photoUrl = event.currentTarget.dataset.photoUrl
    const blobId = event.currentTarget.dataset.blobId

    // Update preview image
    if (this.hasPreviewTarget) {
      this.previewTarget.src = photoUrl
      this.previewTarget.classList.remove("hidden")
    }

    // Update thumbnail preview (step 2)
    if (this.hasPreviewThumbTarget) {
      this.previewThumbTarget.src = photoUrl
    }

    // Hide placeholder
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.add("hidden")
    }

    // Set hidden field with blob ID
    if (this.hasBlobIdTarget) {
      this.blobIdTarget.value = blobId
    }

    // Clear file input (we're using blob ID instead)
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
    }

    // Dispatch event to enable Next button (listened by header controller)
    this.dispatch("selected", { detail: { blobId, photoUrl } })
  }
}
