import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="preview"
export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "previewThumb"];

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
        // Update main preview
        if (this.hasPreviewTarget) {
          this.previewTarget.src = reader.result;
          this.previewTarget.classList.remove("hidden");
        }
        // Update thumbnail preview (for step 2)
        if (this.hasPreviewThumbTarget) {
          this.previewThumbTarget.src = reader.result;
        }
        // Hide placeholder
        if (this.hasPlaceholderTarget) {
          this.placeholderTarget.classList.add("hidden");
        }
      };
      reader.readAsDataURL(file);
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