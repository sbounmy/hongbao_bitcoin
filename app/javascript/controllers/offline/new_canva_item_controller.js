import { Controller } from "@hotwired/stimulus"

// Factory controller for creating new canvas items
// Mirrors the server-side Canva::ItemComponent.for() pattern
export default class extends Controller {
  // --- Public API: Create methods for each item type ---

  createText() {
    this.create('text', {
      text: 'Custom Text',
      fontSize: 3,
      fontColor: '#000000'
    })
  }

  // Future: createImage(), createQrCode(), etc.

  // --- Private: Shared creation logic ---

  create(type, options = {}) {
    const { canvaController, editorController } = this.findControllers()
    if (!canvaController) return

    const name = this.generateName(type)
    const element = this.buildElement(type, name, options)

    // Insert into DOM
    canvaController.containerTarget.after(element)

    // Redraw, persist, and auto-select after Stimulus connects
    // persistChanges() will dispatch editor:changed event which syncs to PDF preview
    requestAnimationFrame(() => {
      canvaController.redrawAll()
      editorController?.persistChanges()

      // Auto-select the new item
      if (editorController) {
        const itemController = canvaController.getItemController(element)
        if (itemController) {
          editorController.selectItem(itemController)
        }
      }
    })
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

  buildElement(type, name, options) {
    const element = document.createElement('div')

    // Common attributes for all item types
    element.classList.add('canva-item')
    element.dataset.canvaTarget = 'canvaItem'

    // Type-specific configuration
    switch (type) {
      case 'text':
        this.configureTextItem(element, name, options)
        break
      // Future: case 'image': this.configureImageItem(element, name, options); break
      // Future: case 'qrcode': this.configureQrCodeItem(element, name, options); break
    }

    return element
  }

  configureTextItem(element, name, options) {
    element.dataset.controller = 'text-item'
    element.dataset.textItemXValue = options.x ?? 10
    element.dataset.textItemYValue = options.y ?? 10
    element.dataset.textItemWidthValue = options.width ?? 30
    element.dataset.textItemHeightValue = options.height ?? 10
    element.dataset.textItemNameValue = name
    element.dataset.textItemTextValue = options.text ?? 'Text'
    element.dataset.textItemFontSizeValue = options.fontSize ?? 3
    element.dataset.textItemFontColorValue = options.fontColor ?? '#000000'
    element.dataset.textItemPresenceValue = false  // Custom items can be deleted
    element.dataset.textItemTypeValue = 'text'
  }

  // Future: configureImageItem(), configureQrCodeItem(), etc.
}
