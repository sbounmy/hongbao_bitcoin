import { Controller } from "@hotwired/stimulus"

// Factory controller for creating new canvas items
// Adds items to JSON, then lets canva_controller sync to create instances
export default class extends Controller {
  // --- Public API: Create methods for each item type ---

  createText() {
    this.create('text', {
      text: 'Custom Text',
      font_size: 3,
      font_color: '#000000'
    })
  }

  // Future: createImage(), createQrCode(), etc.

  // --- Private: Shared creation logic ---

  create(type, options = {}) {
    const { canvaController, editorController } = this.findControllers()
    if (!canvaController) return

    const name = this.generateName(type)
    const data = this.buildItemData(type, options)

    // Add to canva controller's items via JSON field
    const field = canvaController.elementsFieldTarget
    if (!field) return

    try {
      const elements = JSON.parse(field.value || '{}')
      elements[name] = data
      field.value = JSON.stringify(elements)

      // Sync items from JSON
      canvaController.loadItemsFromJson()
      canvaController.redrawAll()

      // Persist and auto-select the new item
      if (editorController) {
        editorController.persistChanges()

        // Auto-select after a frame (item needs to be created first)
        requestAnimationFrame(() => {
          const item = canvaController.getItem(name)
          if (item) {
            editorController.selectItem(item)
          }
        })
      }
    } catch {
      // Ignore parse errors
    }
  }

  findControllers() {
    // Find the active editor (the one with activeValue = true)
    const activeEditorElement = document.querySelector('[data-controller~="editor"][data-editor-active-value="true"]')

    // Fallback to first editor if none active
    const editorElement = activeEditorElement ||
      document.querySelector('[data-controller~="editor"]')

    if (!editorElement) return {}

    const editorController = this.application.getControllerForElementAndIdentifier(editorElement, 'editor')

    // Get the canva controller from within the editor
    const canvaController = editorController?.canvaController

    return { canvaController, editorController }
  }

  generateName(type) {
    return `custom${type.charAt(0).toUpperCase() + type.slice(1)}${Date.now()}`
  }

  buildItemData(type, options = {}) {
    return {
      x: options.x ?? 10,
      y: options.y ?? 10,
      width: options.width ?? 30,
      height: options.height ?? 10,
      rotation: 0,
      presence: false,  // Custom items can be deleted
      hidden: false,
      type: type,
      text: options.text ?? 'Text',
      font_size: options.font_size ?? 3,
      font_color: options.font_color ?? '#000000'
    }
  }
}
