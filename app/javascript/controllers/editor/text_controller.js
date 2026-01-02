import { Controller } from "@hotwired/stimulus"

// Controller for the text edit drawer
// Opens via data-action="editor:drawerOpen->text-edit#open"
export default class extends Controller {
  static targets = ["text", "size", "sizeLabel", "colorPicker", "deleteBtn"]

  engine = null
  elementId = null
  element_ = null

  // Called via data-action="editor:drawerOpen->text-edit#open"
  open(event) {
    const { element, elementId, engine } = event.detail
    this.engine = engine
    this.elementId = elementId
    this.element_ = element

    this.populateForm(element)
    this.updateDeleteButton(element)
  }

  populateForm(element) {
    if (this.hasTextTarget) {
      this.textTarget.value = element.text || ""
    }

    if (this.hasSizeTarget) {
      this.sizeTarget.value = element.font_size || 3
      this.updateSizeLabel()
    }

    if (this.hasColorPickerTarget) {
      this.colorPickerTarget.value = element.font_color || "#000000"
    }
  }

  updateDeleteButton(element) {
    if (!this.hasDeleteBtnTarget) return

    // Hide delete for presence items (required elements)
    const isPresence = element?.presence ?? true
    this.deleteBtnTarget.classList.toggle("hidden", isPresence)
  }

  updateText() {
    if (!this.engine || !this.hasTextTarget) return

    this.engine.updateElement(this.elementId, { text: this.textTarget.value })
  }

  updateSize() {
    if (!this.engine || !this.hasSizeTarget) return

    this.engine.updateElement(this.elementId, { font_size: parseFloat(this.sizeTarget.value) })
    this.updateSizeLabel()
  }

  updateSizeLabel() {
    if (this.hasSizeLabelTarget && this.hasSizeTarget) {
      this.sizeLabelTarget.textContent = `${this.sizeTarget.value}%`
    }
  }

  selectColor(event) {
    const color = event.currentTarget.dataset.color
    if (!color || !this.engine) return

    this.engine.updateElement(this.elementId, { font_color: color })

    if (this.hasColorPickerTarget) {
      this.colorPickerTarget.value = color
    }
  }

  updateColor() {
    if (!this.engine || !this.hasColorPickerTarget) return

    this.engine.updateElement(this.elementId, { font_color: this.colorPickerTarget.value })
  }

  delete() {
    if (!this.engine) return

    // Select element first if not selected
    const current = this.engine.selection.current
    if (!current || (current.id || current.name) !== this.elementId) {
      const el = this.engine.state.elements.find(e => (e.id || e.name) === this.elementId)
      if (el) {
        this.engine.selection.select(el)
      }
    }

    this.engine.deleteSelected()
    this.close()
  }

  close() {
    this.engine = null
    this.elementId = null
    this.element_ = null
    this.element.closest("dialog")?.close()
  }
}
