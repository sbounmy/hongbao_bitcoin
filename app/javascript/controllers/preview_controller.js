import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="previews"
export default class extends Controller {
  static targets = ["input", "preview"];
  connect() {
    if (this.inputTarget.files && this.inputTarget.files[0]) {
      let input = this.inputTarget;
      let preview = this.previewTarget;
      let file = input.files[0];

      if (file) {
        let reader = new FileReader();
        reader.onloadend = () => {
          preview.src = reader.result;
        };
        reader.readAsDataURL(file);
        this.dispatch("selected", { detail: { file } });
      } else {
        preview.src = "";
        this.dispatch("none", { detail: {} });
      }
    }
  }
  preview() {
    // TODO: this
    console.log("preview");
    let input = this.inputTarget;
    let preview = this.previewTarget;
    let file = input.files[0];
    let reader = new FileReader();

    reader.onloadend = function () {
      preview.src = reader.result;
    };

    if (file) {
      reader.readAsDataURL(file);
      this.dispatch("selected", { detail: { file } });
    } else {
      preview.src = "";
      this.dispatch("none", { detail: {} });
    }
  }
}