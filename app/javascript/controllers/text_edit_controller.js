import { Controller } from "@hotwired/stimulus"

// Controller for the text edit drawer
// Binds to a text item and updates it in real-time
export default class extends Controller {
  static targets = ["text", "size", "sizeLabel", "colorPicker", "deleteBtn"]

  connect() {
    // Listen for text-edit:open events from text items
    this.boundOnOpen = this.onOpen.bind(this)
    document.addEventListener("text-edit:open", this.boundOnOpen)

    // Clear state on connect
    this.currentItemElement = null
    this.currentEditorElement = null
  }

  disconnect() {
    document.removeEventListener("text-edit:open", this.boundOnOpen)
    this.currentItemElement = null
    this.currentEditorElement = null
  }

  // Get the current item controller (fresh lookup to avoid stale references)
  get currentItem() {
    if (!this.currentItemElement) return null
    const controllerName = this.currentItemElement.dataset.controller
    return this.application.getControllerForElementAndIdentifier(this.currentItemElement, controllerName)
  }

  // Get the editor controller for this item
  get editorController() {
    if (!this.currentEditorElement) return null
    return this.application.getControllerForElementAndIdentifier(this.currentEditorElement, 'editor')
  }

  onOpen(event) {
    const { itemController } = event.detail
    if (!itemController || !itemController.element) return

    // Store element references (not controller references which can become stale)
    this.currentItemElement = itemController.element
    this.currentEditorElement = itemController.element.closest('[data-controller~="editor"]')

    this.populateForm()
    this.updateDeleteButton()
  }

  populateForm() {
    const item = this.currentItem
    if (!item) return

    // Populate text
    if (this.hasTextTarget) {
      this.textTarget.value = item.textValue || ""
    }

    // Populate size
    if (this.hasSizeTarget) {
      this.sizeTarget.value = item.fontSizeValue || 3
      this.updateSizeLabel()
    }

    // Populate color
    if (this.hasColorPickerTarget) {
      this.colorPickerTarget.value = item.fontColorValue || "#000000"
    }
  }

  updateDeleteButton() {
    if (!this.hasDeleteBtnTarget) return

    const item = this.currentItem
    // Hide delete for presence items (required elements)
    const isPresence = item?.presenceValue ?? true
    this.deleteBtnTarget.classList.toggle("hidden", isPresence)
  }

  updateText() {
    const item = this.currentItem
    if (!item || !this.hasTextTarget) return

    item.textValue = this.textTarget.value
    this.redrawAndPersist()
  }

  updateSize() {
    const item = this.currentItem
    if (!item || !this.hasSizeTarget) return

    item.fontSizeValue = parseFloat(this.sizeTarget.value)
    this.updateSizeLabel()
    this.redrawAndPersist()
  }

  updateSizeLabel() {
    if (this.hasSizeLabelTarget && this.hasSizeTarget) {
      this.sizeLabelTarget.textContent = `${this.sizeTarget.value}%`
    }
  }

  selectColor(event) {
    const color = event.currentTarget.dataset.color
    const item = this.currentItem
    if (!color || !item) return

    item.fontColorValue = color

    if (this.hasColorPickerTarget) {
      this.colorPickerTarget.value = color
    }
    this.redrawAndPersist()
  }

  updateColor() {
    const item = this.currentItem
    if (!item || !this.hasColorPickerTarget) return

    item.fontColorValue = this.colorPickerTarget.value
    this.redrawAndPersist()
  }

  delete() {
    const item = this.currentItem
    if (!item || item.presenceValue) return

    const editor = this.editorController
    if (editor) {
      // Select the item first so deleteSelected works
      editor.selectItem(item)
      editor.deleteSelected()
    }

    // Close the drawer
    document.getElementById("text-edit-drawer")?.close()
    this.currentItemElement = null
    this.currentEditorElement = null
  }

  redrawAndPersist() {
    const item = this.currentItem
    if (!item) return

    const canvaController = item.canvaController
    if (canvaController) {
      canvaController.redrawAll()

      const editor = this.editorController
      if (editor) {
        // Persist and dispatch to sync PDF preview
        editor.persistChanges()
      }
    }
  }
}
