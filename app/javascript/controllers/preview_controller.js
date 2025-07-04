import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="previews"
export default class extends Controller {
  static targets = ["input", "preview"];
  
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
        this.previewTarget.src = reader.result;
      };
      reader.readAsDataURL(file);
      this.dispatch("selected", { detail: { file } });
    } else {
      this.previewTarget.src = "";
      this.dispatch("none", { detail: {} });
    }
  }
}