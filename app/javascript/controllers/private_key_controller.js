import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["warning", "content", "copyButton"]

  reveal(event) {
    if (confirm("Are you sure you want to reveal the private key? Never share it with anyone.")) {
      this.warningTarget.style.display = "none"
      this.contentTarget.style.display = "block"
      this.copyButtonTarget.style.display = "block"
    }
  }
}