import { Controller } from "@hotwired/stimulus"
import Dialog from "@stimulus-components/dialog"

export default class extends Dialog {
  static values = {
    accepted: { type: Boolean, default: false }
  }

  open(event) {
    // if pressed key is not a printable character we don't want to open the dialog
    if (!event.key.match(/^.$/)) {
      return
    }

    if (!this.acceptedValue) {
      super.open()
    }
  }

  accept(event) {
    this.acceptedValue = true
    super.close()
  }


  reset() {
    this.acceptedValue = false
  }
}