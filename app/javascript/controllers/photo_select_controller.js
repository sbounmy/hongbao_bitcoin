import { Controller } from "@hotwired/stimulus"

// Handles photo grid selection and "Done" button canvas dispatch
export default class extends Controller {
  static targets = ["preview", "placeholder", "blobId", "input"]

  select(event) {
    event.preventDefault()
    const photoUrl = event.currentTarget.dataset.photoUrl
    const blobId = event.currentTarget.dataset.blobId

    // Update drawer preview
    if (this.hasPreviewTarget) {
      this.previewTarget.src = photoUrl
      this.previewTarget.classList.remove("hidden")
    }
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.add("hidden")
    }

    // Set hidden blob_id field
    if (this.hasBlobIdTarget) {
      this.blobIdTarget.value = blobId
    }

    // Clear file input (using blob instead)
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
    }

    // Store for done() method
    this.selectedPhotoUrl = photoUrl

    // Local event only
    this.dispatch("selected", { detail: { blobId, photoUrl } })
  }

  // Called by "Done" button - dispatches to canvas
  done() {
    // Priority: file upload > existing photo selection
    if (this.hasInputTarget && this.inputTarget.files?.[0]) {
      const file = this.inputTarget.files[0]
      this.dispatch("selected", {
        detail: { file },
        prefix: "preview",
        bubbles: true
      })
    } else if (this.selectedPhotoUrl) {
      this.dispatch("selected", {
        detail: { url: this.selectedPhotoUrl },
        prefix: "preview",
        bubbles: true
      })
    }
  }
}
