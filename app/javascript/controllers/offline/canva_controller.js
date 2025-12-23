import { Controller } from "@hotwired/stimulus"

// Generic canvas container - manages background and coordinates item drawing
// Portrait, text, and image items are handled by their own controllers
export default class extends Controller {
  static targets = ["container", "canvaItem", "backgroundImage"]
  static values = {
    width: Number,   // Canvas width in pixels
    height: Number,  // Canvas height in pixels
    strict: Boolean, // Strict mode: use exact frame dimensions (for PDF)
    side: String     // Which side: "front" or "back"
  }

  connect() {
    // Defer initialization until element is visible (has dimensions)
    this.resizeObserver = new ResizeObserver(() => {
      const canvas = this.containerTarget
      if (canvas.parentElement.offsetWidth > 0 && !this.isInitialized) {
        this.isInitialized = true
        this.resizeObserver.disconnect()
        this.initializeCanvas()
        // Sync from layout JSON to get custom text items (may have been created before this canvas was visible)
        this.syncFromLayoutJson()
        this.loadBackgroundImage()
      }
    })
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  // Handle wallet changes - sync wallet data from JSON and redraw
  // JSON is the source of truth (written by bitcoin_controller)
  handleWalletChanged() {
    if (!this.isInitialized) return

    this.syncFromWalletJson()
    this.redrawAll()
  }

  // Handle layout/element changes - sync positions and custom items from JSON
  // JSON is the source of truth (written by editor_controller)
  async handleElementsChanged(event) {
    const { side } = event.detail || {}

    // Only sync if this canvas matches the side (front or back)
    if (side && this.sideValue && side !== this.sideValue) {
      return
    }

    if (!this.isInitialized) return

    await this.syncFromLayoutJson()
    this.redrawAll()
  }

  // Read layout JSON (positions, custom text) and sync items
  async syncFromLayoutJson() {
    const field = document.querySelector(`input[name="${this.sideValue}_elements"]`)
    if (!field?.value) return

    try {
      const elements = JSON.parse(field.value)
      await this.syncItemsWithElements(elements)
    } catch {
      // Ignore parse errors
    }
  }

  // Read wallet JSON (text values, QR codes) and sync items
  syncFromWalletJson() {
    const field = document.querySelector(`input[name="${this.sideValue}_wallet"]`)
    if (!field?.value) return

    try {
      const wallet = JSON.parse(field.value)

      console.log('wallet:', wallet)
      // Update wallet-related items from JSON
      this.canvaItemTargets.forEach(item => {
        const controller = this.getItemController(item)
        console.log('controller', controller)
        console.log('item', item)
        if (!controller) return

        const name = controller.nameValue
        console.log('name:', name)
        console.log('wallet: ', wallet)
        // For text items (mnemonicText, privateKeyText, publicAddressText)
        if (wallet[name] !== undefined && controller.textValue !== undefined) {
          controller.textValue = wallet[name]
        }

        // For QR code items (publicAddressQrcode, privateKeyQrcode)
        if (wallet[name] !== undefined && controller.syncFromWallet) {
          controller.syncFromWallet(wallet)
        }
      })
    } catch {
      // Ignore parse errors
    }
  }

  // Sync canvas items to match elements data (single source of truth pattern)
  // Handles CREATE, UPDATE, and DELETE in one pass
  syncItemsWithElements(elements) {
    const existingNames = new Set()
    let createdNew = false

    // Update or remove existing items
    this.canvaItemTargets.forEach(item => {
      const controller = this.getItemController(item)
      if (controller) {
        const name = controller.nameValue
        existingNames.add(name)

        if (elements[name]) {
          // Update existing item
          controller.updateFromElements(elements[name])
        } else {
          // Item was deleted - remove from DOM
          item.remove()
        }
      }
    })

    // Create new items (not in existing)
    Object.entries(elements).forEach(([name, data]) => {
      if (!existingNames.has(name)) {
        this.createItemFromData(name, data)
        createdNew = true
      }
    })

    // If we created new items, wait for Stimulus to connect
    // Caller is responsible for calling redrawAll()
    if (createdNew) {
      return new Promise(resolve => requestAnimationFrame(resolve))
    }
  }

  // Create a canvas item from element data
  createItemFromData(name, data) {
    const element = document.createElement('div')
    element.classList.add('canva-item')
    element.dataset.canvaTarget = 'canvaItem'

    // Determine type from data or name pattern
    const isQrCode = name.endsWith('Qrcode') || name.endsWith('_qrcode')

    if (isQrCode) {
      element.dataset.controller = 'image-item'
      element.dataset.imageItemXValue = data.x
      element.dataset.imageItemYValue = data.y
      element.dataset.imageItemWidthValue = data.width
      element.dataset.imageItemHeightValue = data.height
      element.dataset.imageItemNameValue = name
    } else {
      // Text item (default)
      element.dataset.controller = 'text-item'
      element.dataset.textItemXValue = data.x
      element.dataset.textItemYValue = data.y
      element.dataset.textItemWidthValue = data.width
      element.dataset.textItemHeightValue = data.height
      element.dataset.textItemNameValue = name
      element.dataset.textItemTextValue = data.text || ''
      element.dataset.textItemFontSizeValue = data.font_size || 3
      element.dataset.textItemFontColorValue = data.font_color || '#000000'
      element.dataset.textItemPresenceValue = data.presence ?? false
      element.dataset.textItemTypeValue = data.type || 'text'
    }

    // Insert into DOM
    this.containerTarget.after(element)
  }

  initializeCanvas() {
    const canvas = this.containerTarget
    this.qualityScale = 3

    // Store container dimensions for display sizing
    this.containerWidth = canvas.parentElement.offsetWidth
    this.containerHeight = canvas.parentElement.offsetHeight

    // Initialize with fallback dimensions (will be updated when image loads)
    this.originalWidth = this.widthValue || this.containerWidth
    this.originalHeight = this.heightValue || this.containerHeight

    // Set initial canvas size
    this.setupCanvasSize(canvas)

    // Initial draw if background image exists
    if (this.hasBackgroundImageTarget) {
      this.loadBackgroundImage()
    }
  }

  setupCanvasSize(canvas) {
    // Internal resolution uses actual image dimensions for quality
    canvas.width = this.originalWidth * this.qualityScale
    canvas.height = this.originalHeight * this.qualityScale

    let displayWidth, displayHeight

    if (this.strictValue) {
      // Strict mode: use exact frame dimensions (for PDF printing)
      displayWidth = this.widthValue
      displayHeight = this.heightValue
    } else {
      // Responsive mode: fit container while maintaining aspect ratio
      const aspectRatio = this.originalWidth / this.originalHeight
      displayWidth = this.containerWidth
      displayHeight = displayWidth / aspectRatio

      // If too tall, constrain by height instead
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

      // Use actual image dimensions for correct aspect ratio
      // This matches composition.rb which uses template_image.width/height
      this.originalWidth = this.backgroundImage.width
      this.originalHeight = this.backgroundImage.height
      this.setupCanvasSize(this.containerTarget)

      this.dispatch("imageLoaded")
    }
  }

  backgroundImageChanged(event) {
    this.backgroundImageTarget.src = event.detail.url

    // Update existing items' positions instead of recreating them
    // This preserves drawer connections and other server-rendered attributes
    if (event.detail.elements) {
      this.updateCanvaItemPositions(event.detail.elements)
    }

    this.loadBackgroundImage()
  }

  // Update existing canva items with new positions from theme
  updateCanvaItemPositions(elements) {
    this.canvaItemTargets.forEach(item => {
      const controller = this.getItemController(item)
      if (controller) {
        const itemName = controller.nameValue
        if (elements[itemName]) {
          controller.updateFromElements(elements[itemName])
        }
      }
    })
  }

  clearCanvaItems() {
    this.canvaItemTargets.forEach(item => {
      item.remove()
    })
  }
  camelize(name) {
    return name
      .split('_')
      .map((word, index) =>
        index === 0 ? word.toLowerCase() : word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
      )
      .join('')
  }

  createCanvaItems(elements) {
    Object.keys(elements).forEach(name => {
      const element = elements[name]
      const canvaItem = document.createElement('div')
      const isQrCode = name.endsWith('_qrcode')
      const isMnemonic = name.startsWith('mnemonic')

      // Use specific controller types
      const controllerName = isQrCode ? 'image-item' : 'text-item'
      const prefix = isQrCode ? 'imageItem' : 'textItem'

      canvaItem.dataset.controller = controllerName
      canvaItem.dataset[`${prefix}XValue`] = element.x
      canvaItem.dataset[`${prefix}YValue`] = element.y
      canvaItem.dataset[`${prefix}NameValue`] = this.camelize(name)
      canvaItem.dataset[`${prefix}WidthValue`] = element.width
      canvaItem.dataset[`${prefix}HeightValue`] = element.height

      if (!isQrCode) {
        // Text-specific properties
        canvaItem.dataset[`${prefix}TextValue`] = element.text
        canvaItem.dataset[`${prefix}TypeValue`] = isMnemonic ? 'mnemonic' : 'text'
        canvaItem.dataset[`${prefix}FontSizeValue`] = element.size
        canvaItem.dataset[`${prefix}FontColorValue`] = element.color
      }

      canvaItem.classList.add('canva-item')
      canvaItem.classList.add('generated')
      canvaItem.dataset.canvaTarget = 'canvaItem'
      this.containerTarget.after(canvaItem)
    })
  }

  clear() {
    if (!this.ctx) return

    this.ctx.clearRect(0, 0, this.originalWidth, this.originalHeight)
    if (this.backgroundImage) {
      this.ctx.drawImage(
        this.backgroundImage,
        0,
        0,
        this.originalWidth,
        this.originalHeight
      )
    }
  }

  // Schedule a redraw for the next animation frame (throttled)
  // Use this during continuous interactions (drag, resize, pinch) to avoid excessive redraws
  scheduleRedraw() {
    if (this._redrawScheduled) return
    this._redrawScheduled = true
    requestAnimationFrame(() => {
      this._redrawScheduled = false
      this.redrawAll()
    })
  }

  // Called by canva items when they need to redraw the entire canvas
  // (e.g., portrait loading animation, image loaded)
  // For continuous interactions, prefer scheduleRedraw() instead
  redrawAll() {
    this.clear()
    this.canvaItemTargets.forEach(item => {
      // Get controller dynamically - could be text-item, image-item, or portrait-item
      const controllerName = item.dataset.controller
      const controller = this.application.getControllerForElementAndIdentifier(item, controllerName)
      controller?.draw()
    })
  }

  // Get controller for a canva item (handles different controller types)
  getItemController(item) {
    const controllerName = item.dataset.controller
    return this.application.getControllerForElementAndIdentifier(item, controllerName)
  }

  // Get the name value from an item (handles different controller prefixes)
  getItemName(item) {
    const controllerName = item.dataset.controller
    const prefix = controllerName.replace(/-/g, '')
    return item.dataset[`${prefix}NameValue`]
  }

  // Set hidden value for an item (handles different controller prefixes)
  setItemHidden(item, hidden) {
    const controllerName = item.dataset.controller
    const prefix = controllerName.replace(/-/g, '')
    item.dataset[`${prefix}HiddenValue`] = hidden
  }

  hide(names) {
    names = [names].flat()
    this.canvaItemTargets.forEach(item => {
      if (names.includes(this.getItemName(item))) {
        this.setItemHidden(item, true)
      }
    })
  }

  show(names) {
    names = [names].flat()
    this.canvaItemTargets.forEach(item => {
      if (names.includes(this.getItemName(item))) {
        this.setItemHidden(item, false)
      }
    })
  }

  // Redraw the canvas without any changing data (usually ui mode changed)
  refresh(event) {
    if (!this.isInitialized) return

    this.hide(event.detail.hide)
    this.show(event.detail.show)
    this.clear()
    this.canvaItemTargets.forEach(item => {
      this.getItemController(item)?.draw()
    })
  }
}
