import { Controller } from "@hotwired/stimulus";

// Handles file input and drawer preview display ONLY
// Does NOT dispatch to canvas - that's photo_select_controller's job
export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "previewThumb", "blobId"];

  connect() {
    this.updatePreview();
  }

  preview() {
    this.updatePreview();
  }

  updatePreview() {
    const file = this.inputTarget.files?.[0];

    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        // Update drawer preview only
        if (this.hasPreviewTarget) {
          this.previewTarget.src = reader.result;
          this.previewTarget.classList.remove("hidden");
        }
        if (this.hasPreviewThumbTarget) {
          this.previewThumbTarget.src = reader.result;
        }
        if (this.hasPlaceholderTarget) {
          this.placeholderTarget.classList.add("hidden");
        }
      };
      reader.readAsDataURL(file);

      // Clear blob ID when uploading new file
      if (this.hasBlobIdTarget) {
        this.blobIdTarget.value = "";
      }

      // Local event only - NO window dispatch
      // Canvas update happens via photo_select_controller.done()
      this.dispatch("selected", { detail: { file } });
    } else {
      if (this.hasPreviewTarget) {
        this.previewTarget.src = "";
        this.previewTarget.classList.add("hidden");
      }
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.remove("hidden");
      }
      this.dispatch("none", { detail: {} });
    }
  }
}