import { Controller } from "@hotwired/stimulus"
import { createItem } from "./item"

// Generic canvas container - manages background and coordinates item drawing
// Items are plain JS objects instantiated from JSON (single source of truth)
export default class extends Controller {
  static targets = ["container", "backgroundImage", "elementsField"]
  static values = {
    width: Number,   // Canvas width in pixels
    height: Number,  // Canvas height in pixels
    strict: Boolean, // Strict mode: use exact frame dimensions (for PDF)
    side: String,    // Which side: "front" or "back"
    themeId: String  // Current theme ID for per-theme state caching
  }

  connect() {
    // Items map: name -> item instance
    this.items = new Map()

    // Per-theme state cache: themeId -> elements JSON
    this.themeElementsCache = new Map()

    // Defer initialization until element is visible (has dimensions)
    this.resizeObserver = new ResizeObserver(() => {
      const canvas = this.containerTarget
      if (canvas.parentElement.offsetWidth > 0 && !this.isInitialized) {
        this.isInitialized = true
        this.resizeObserver.disconnect()
        this.initializeCanvas()
        this.loadItemsFromJson()
        this.loadBackgroundImage()
      }
    })
    this.resizeObserver.observe(this.element)

    // Listen for canvas clicks to handle item selection
    this.containerTarget.addEventListener("click", this.handleCanvasClick.bind(this))
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    // Clean up items (e.g., portrait event listeners)
    this.items.forEach(item => item.destroy?.())
    this.items.clear()
  }

  // Handle clicks on the canvas - find which item was clicked
  handleCanvasClick(event) {
    const rect = this.containerTarget.getBoundingClientRect()
    const scaleX = this.originalWidth / rect.width
    const scaleY = this.originalHeight / rect.height

    // Convert click to percentage coordinates
    const clickX = ((event.clientX - rect.left) * scaleX / this.originalWidth) * 100
    const clickY = ((event.clientY - rect.top) * scaleY / this.originalHeight) * 100

    // Find item at click position (reverse order for top-most first)
    const itemsArray = Array.from(this.items.values()).reverse()
    const clickedItem = itemsArray.find(item => !item.hidden && item.containsPoint(clickX, clickY))

    if (clickedItem) {
      this.selectItem(clickedItem)
    }
  }

  // Select an item and notify editor
  selectItem(item) {
    this.selectedItem = item

    // Dispatch event for editor controller
    this.dispatch("itemSelected", {
      detail: { item, name: item.name }
    })
  }

  // Handle wallet changes - sync wallet data from JSON and redraw
  handleWalletChanged() {
    if (!this.isInitialized) return
    this.syncFromWalletJson()
    this.redrawAll()
  }

  // Handle layout/element changes - sync positions and custom items from JSON
  handleElementsChanged(event) {
    const { side } = event.detail || {}

    // Only sync if this canvas matches the side
    if (side && this.sideValue && side !== this.sideValue) {
      return
    }

    if (!this.isInitialized) return
    this.loadItemsFromJson()
    this.redrawAll()
  }

  // Load items from the elements JSON field
  loadItemsFromJson() {
    const field = this.hasElementsFieldTarget
      ? this.elementsFieldTarget
      : document.querySelector(`input[name="${this.sideValue}_elements"]`)

    if (!field?.value) return

    try {
      const elements = JSON.parse(field.value)
      this.syncItems(elements)
    } catch {
      // Ignore parse errors
    }
  }

  // Sync items map with elements data (uses snake_case names throughout)
  syncItems(elements) {
    const newNames = new Set()

    Object.entries(elements).forEach(([name, data]) => {
      // Use snake_case names directly (no conversion needed)
      newNames.add(name)

      if (this.items.has(name)) {
        // Update existing item
        this.items.get(name).updateFromData(data)
      } else {
        // Create new item
        const item = createItem(name, data, this)
        this.items.set(name, item)
      }
    })

    // Remove items that no longer exist in JSON
    for (const [name, item] of this.items) {
      if (!newNames.has(name)) {
        item.destroy?.()
        this.items.delete(name)
      }
    }
  }

  // Read wallet JSON and sync text/QR data to items
  syncFromWalletJson() {
    const field = document.querySelector(`input[name="${this.sideValue}_wallet"]`)
    if (!field?.value) return

    try {
      const wallet = JSON.parse(field.value)

      this.items.forEach((item, name) => {
        // Both item names and wallet keys use snake_case - direct match
        if (wallet[name] !== undefined && item.text !== undefined) {
          item.text = wallet[name]
        }

        if (wallet[name] !== undefined && item.syncFromWallet) {
          item.syncFromWallet(wallet, name)
        }
      })
    } catch {
      // Ignore parse errors
    }
  }

  initializeCanvas() {
    const canvas = this.containerTarget
    this.qualityScale = 3

    this.containerWidth = canvas.parentElement.offsetWidth
    this.containerHeight = canvas.parentElement.offsetHeight

    this.originalWidth = this.widthValue || this.containerWidth
    this.originalHeight = this.heightValue || this.containerHeight

    this.setupCanvasSize(canvas)

    if (this.hasBackgroundImageTarget) {
      this.loadBackgroundImage()
    }
  }

  setupCanvasSize(canvas) {
    canvas.width = this.originalWidth * this.qualityScale
    canvas.height = this.originalHeight * this.qualityScale

    let displayWidth, displayHeight

    if (this.strictValue) {
      displayWidth = this.widthValue
      displayHeight = this.heightValue
    } else {
      const aspectRatio = this.originalWidth / this.originalHeight
      displayWidth = this.containerWidth
      displayHeight = displayWidth / aspectRatio

      if (displayHeight > this.containerHeight) {
        displayHeight = this.containerHeight
        displayWidth = displayHeight * aspectRatio
      }
    }

    canvas.style.width = `${displayWidth}px`
    canvas.style.height = `${displayHeight}px`

    this.ctx = canvas.getContext('2d')
    this.ctx.setTransform(1, 0, 0, 1, 0, 0)
    this.ctx.scale(this.qualityScale, this.qualityScale)
    this.ctx.imageSmoothingEnabled = true
    this.ctx.imageSmoothingQuality = 'high'
  }

  loadBackgroundImage() {
    if (!this.backgroundImageTarget) return

    const img = new Image()
    img.src = this.backgroundImageTarget.src
    img.onload = (event) => {
      this.backgroundImage = event.target
      this.originalWidth = this.backgroundImage.width
      this.originalHeight = this.backgroundImage.height
      this.setupCanvasSize(this.containerTarget)
      this.dispatch("imageLoaded")
      this.redrawAll()
    }
  }

  backgroundImageChanged(event) {
    const { themeId, url, elements: themeDefaults } = event.detail

    // Save current theme's elements to cache
    if (this.themeIdValue && this.hasElementsFieldTarget) {
      try {
        const currentElements = JSON.parse(this.elementsFieldTarget.value)
        this.themeElementsCache.set(this.themeIdValue, currentElements)
      } catch { /* ignore */ }
    }

    // Get elements for new theme
    const cachedElements = this.themeElementsCache.get(String(themeId))
    const newElements = cachedElements || themeDefaults

    if (themeId) {
      this.themeIdValue = String(themeId)
    }

    // Update hidden field and sync items
    if (this.hasElementsFieldTarget && newElements) {
      this.elementsFieldTarget.value = JSON.stringify(newElements)
      this.syncItems(newElements)
    }

    this.backgroundImageTarget.src = url
    this.loadBackgroundImage()
  }

  clear() {
    if (!this.ctx) return

    this.ctx.clearRect(0, 0, this.originalWidth, this.originalHeight)
    if (this.backgroundImage) {
      this.ctx.drawImage(
        this.backgroundImage,
        0, 0,
        this.originalWidth,
        this.originalHeight
      )
    }
  }

  // Schedule a redraw for the next animation frame (throttled)
  scheduleRedraw() {
    if (this._redrawScheduled) return
    this._redrawScheduled = true
    requestAnimationFrame(() => {
      this._redrawScheduled = false
      this.redrawAll()
    })
  }

  redrawAll() {
    this.clear()
    this.items.forEach(item => item.draw())
  }

  // Get an item by name (snake_case)
  getItem(name) {
    return this.items.get(name)
  }

  // Hide items by name(s)
  hide(names) {
    [names].flat().forEach(name => {
      const item = this.getItem(name)
      if (item) item.hidden = true
    })
  }

  // Show items by name(s)
  show(names) {
    [names].flat().forEach(name => {
      const item = this.getItem(name)
      if (item) item.hidden = false
    })
  }

  // Refresh canvas (e.g., UI mode changed)
  refresh(event) {
    if (!this.isInitialized) return

    this.hide(event.detail.hide)
    this.show(event.detail.show)
    this.redrawAll()
  }

  // Persist current item states back to JSON field
  persistToJson() {
    if (!this.hasElementsFieldTarget) return

    const elements = {}
    this.items.forEach((item, name) => {
      elements[name] = item.toJSON()
    })
    this.elementsFieldTarget.value = JSON.stringify(elements)
  }
}
