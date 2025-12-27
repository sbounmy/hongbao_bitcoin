import { Controller } from "@hotwired/stimulus"

// Controller for the image/photo edit drawer
// Handles image selection and updates the canvas element
export default class extends Controller {
  engine = null
  elementId = null
  element_ = null

  // Called via data-action="editor:drawerOpen@window->image-edit#open"
  // Filters for image elements only (type === 'image')
  open(event) {
    const { element, elementId, engine } = event.detail

    // Only handle image element opens
    if (element?.type !== 'image') return

    this.engine = engine
    this.elementId = elementId
    this.element_ = element
  }

  // Called when photo-select dispatches "preview:selected" event via Done button
  // data-action="photo-select:selected->image-edit#applyImage"
  applyImage(event) {
    if (!this.engine || !this.elementId) return

    const { url, file } = event.detail || {}

    // Get the element instance from the canvas
    const instance = this.engine.canvases.getInstanceById(this.elementId)
    if (!instance) return

    if (file) {
      // File was uploaded - convert to data URL and load
      const reader = new FileReader()
      reader.onload = (e) => {
        instance.loadImage(e.target.result)
        this.engine.scheduleRender()
      }
      reader.readAsDataURL(file)
    } else if (url) {
      // Existing photo was selected - load from URL
      instance.loadImage(url)
      this.engine.scheduleRender()
    }
  }

  close() {
    this.engine = null
    this.elementId = null
    this.element_ = null
  }
}
