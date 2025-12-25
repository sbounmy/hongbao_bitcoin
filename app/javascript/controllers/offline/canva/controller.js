import { Controller } from "@hotwired/stimulus"
import { createItem } from "./item"

// Generic canvas container - manages background and coordinates item drawing
// Items are plain JS objects instantiated from JSON (single source of truth)
export default class extends Controller {
  static targets = ["container", "backgroundImage", "walletField"]
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
      const parentWidth = canvas.parentElement.offsetWidth

      if (parentWidth > 0 && !this.isInitialized) {
        this.isInitialized = true
        this.resizeObserver.disconnect()
        this.initializeCanvas()
        this.loadBackgroundImage()
        // Load initial items from storage
        this.loadInitialItems()
      }
    })
    this.resizeObserver.observe(this.element)

    // Listen for canvas clicks to handle item selection
    this.containerTarget.addEventListener("click", this.handleCanvasClick.bind(this))
  }

  // Load initial items by querying storage directly (called on init)
  loadInitialItems() {
    const elements = this.getCurrentElementsForSide() || {}
    this.syncItems(elements)
    // Also sync wallet data (text content for keys/addresses)
    this.syncFromWalletJson()
  }

  // Handle storage ready event (for late initialization)
  handleStorageReady(event) {
    if (!this.isInitialized) return

    const elements = event.detail[this.sideValue] || {}
    this.syncItems(elements)
    this.redrawAll()
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
    if (!this.hasWalletFieldTarget) return
    this.syncFromWalletJson()
    this.redrawAll()
  }

  // Handle storage changes from the storage controller
  handleStorageChanged(event) {
    console.log("[Canva] handleStorageChanged() side:", this.sideValue)
    if (!this.isInitialized) return

    const elements = event.detail[this.sideValue] || {}
    this.syncItems(elements)
    this.redrawAll()
  }

  // Handle unified theme change event - single event with all elements
  handleThemeChanged(event) {
    const { themeId, frontUrl, backUrl, elements: allElements } = event.detail

    // Get the URL for this side
    const url = this.sideValue === "front" ? frontUrl : backUrl
    if (!url) return

    // Save current theme's elements to cache
    if (this.themeIdValue) {
      const currentElements = this.getCurrentElementsForSide()
      if (currentElements) {
        this.themeElementsCache.set(this.themeIdValue, currentElements)
      }
    }

    // Get elements for new theme
    const cachedElements = this.themeElementsCache.get(String(themeId))

    // Filter all elements to get just this side's elements
    const themeDefaults = Object.fromEntries(
      Object.entries(allElements || {}).filter(([_, data]) => data.side === this.sideValue)
    )

    const newElements = cachedElements || themeDefaults

    if (themeId) {
      this.themeIdValue = String(themeId)
    }

    // Update storage with new elements for this side
    const storageController = this.getStorageController()
    if (storageController && newElements) {
      storageController.updateSide(this.sideValue, newElements)
      this.syncItems(newElements)
    }

    // Update background image
    this.backgroundImageTarget.src = url
    this.loadBackgroundImage()
  }

  // Get storage controller via DOM query (for write operations)
  getStorageController() {
    const storageElement = document.querySelector("[data-controller='editor-storage']")
    if (!storageElement) return null
    return this.application.getControllerForElementAndIdentifier(storageElement, 'editor-storage')
  }

  // Get current elements for this side from storage
  getCurrentElementsForSide() {
    const storageController = this.getStorageController()
    if (!storageController) return null
    return storageController.elementsForSide(this.sideValue)
  }

  // Sync items map with elements data (uses snake_case names throughout)
  syncItems(elements) {
    console.log("[Canva] syncItems() side:", this.sideValue, "element count:", Object.keys(elements).length)
    const newNames = new Set()

    Object.entries(elements).forEach(([name, data]) => {
      // Use snake_case names directly (no conversion needed)
      newNames.add(name)

      if (this.items.has(name)) {
        // Update existing item
        console.log("[Canva] syncItems() updating existing item:", name)
        this.items.get(name).updateFromData(data)
      } else {
        // Create new item
        console.log("[Canva] syncItems() creating new item:", name, "type:", data.type, "data:", data)
        const item = createItem(name, data, this)
        console.log("[Canva] syncItems() created item:", item)
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
    if (!this.hasWalletFieldTarget) {
      console.log("[Canva] syncFromWalletJson() side:", this.sideValue, "- no walletField target")
      return
    }
    if (!this.walletFieldTarget.value) {
      console.log("[Canva] syncFromWalletJson() side:", this.sideValue, "- walletField empty")
      return
    }
    console.log("[Canva] syncFromWalletJson() side:", this.sideValue, "value:", this.walletFieldTarget.value.substring(0, 50))

    try {
      const wallet = JSON.parse(this.walletFieldTarget.value)
      console.log("[Canva] syncFromWalletJson() wallet keys:", Object.keys(wallet))

      this.items.forEach((item, name) => {
        // Both item names and wallet keys use snake_case - direct match
        if (wallet[name] !== undefined && item.text !== undefined) {
          console.log("[Canva] syncFromWalletJson() setting text for:", name)
          item.text = wallet[name]
        }

        if (wallet[name] !== undefined && item.syncFromWallet) {
          console.log("[Canva] syncFromWalletJson() calling syncFromWallet for:", name)
          item.syncFromWallet(wallet, name)
        }
      })
    } catch (e) {
      console.error("[Canva] syncFromWalletJson() error:", e)
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
    console.log("[Canva] redrawAll() side:", this.sideValue, "items count:", this.items.size, "ctx:", !!this.ctx)
    this.clear()
    this.items.forEach((item, name) => {
      console.log("[Canva] redrawAll() drawing item:", name, "hidden:", item.hidden, "type:", item.type)
      item.draw()
    })
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

  // Persist current item states back to storage via event
  persistToJson() {
    const elements = {}
    this.items.forEach((item, name) => {
      elements[name] = item.toJSON()
    })

    this.dispatch("persist", {
      detail: { side: this.sideValue, elements }
    })
  }
}
