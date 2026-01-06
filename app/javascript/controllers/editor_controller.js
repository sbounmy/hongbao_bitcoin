import { Controller } from "@hotwired/stimulus"
import { Engine } from "../editor/engine"
import { Exporter } from "../editor/exporter"

// Paper editor controller - thin Stimulus bridge to the Engine
// Uses HTML/CSS elements for rendering instead of canvas for:
// - Easier E2E testing with data attributes
// - Better text rendering with CSS fonts
// - Simpler debugging in dev tools
export default class extends Controller {
  static targets = [
    "frontContainer",   // Front side container div
    "backContainer",    // Back side container div
    "frontWrapper",     // Front container wrapper (for show/hide)
    "backWrapper",      // Back container wrapper (for show/hide)
    "layoutContainer",  // Container for layout direction (flex-row/flex-col)
    "field",            // Hidden input for elements JSON
    "dataSource",       // Hidden input for external data (e.g., wallet JSON)
    "sideToggle",       // Button showing current side
    "frontBackground",  // Hidden img for front background
    "backBackground",   // Hidden img for back background
    "frontThumbnail",   // Front thumbnail background div
    "backThumbnail"     // Back thumbnail background div
  ]

  static values = {
    design: Object,     // Initial elements state from server
    themeId: String     // Current theme ID
  }

  // Store current frame data for export (from theme selection)
  currentFrameData = null

  // Export DOM elements for PDF preview (instant - no html2canvas)
  // Clones the DOM containers instead of converting to images
  exportForPreview() {
    // Clone front/back containers with all their children
    const frontClone = this.frontContainerTarget.cloneNode(true)
    const backClone = this.backContainerTarget.cloneNode(true)

    // Remove selection overlays from clones
    frontClone.querySelectorAll('.editor-selection-overlay').forEach(el => el.remove())
    backClone.querySelectorAll('.editor-selection-overlay').forEach(el => el.remove())

    // Dispatch clones for preview to insert (include frame data for preview to update)
    this.dispatch("exported", {
      detail: {
        frontEl: frontClone,
        backEl: backClone,
        frameData: this.currentFrameData
      }
    })

    // Trigger step change
    this.dispatch("exportComplete", { bubbles: true, prefix: false })
  }

  async connect() {
    // Get background URLs
    const frontBackground = this.hasFrontBackgroundTarget
      ? this.frontBackgroundTarget.src
      : null
    const backBackground = this.hasBackBackgroundTarget
      ? this.backBackgroundTarget.src
      : null

    // Initialize engine
    this.engine = new Engine(
      this.frontContainerTarget,
      this.backContainerTarget,
      {
        initialState: this.designValue,
        frontBackground,
        backBackground,
        onSelectionChange: (el) => this.handleSelectionChange(el),
        onStateChange: () => this.persistToField(),
        onSideChange: (side) => this.updateSideUI(side),
        onElementEdit: (el) => this.openDrawerForElement(el)
      }
    )

    // Create exporter (uses html2canvas)
    this.exporter = new Exporter(this.engine.canvases, this.engine.state)

    // Start engine and wait for it to be ready
    await this.engine.start()

    // Sync initial external data (after engine is ready and elements are rendered)
    this.syncExternalData()

    // Update UI
    this.updateSideUI(this.engine.activeSide)
  }

  disconnect() {
    this.engine?.destroy()
  }

  // --- External Data Binding ---
  // Called on connect - tries to read from hidden field or wait for event
  syncExternalData() {
    if (!this.hasDataSourceTarget) return

    const dataValue = this.dataSourceTarget.value
    if (!dataValue || dataValue === '{}') return

    try {
      const data = JSON.parse(dataValue)
      this.syncExternalDataFrom(data)
    } catch (e) {
      // Silently fail - wallet data will come via event
    }
  }

  // Sync wallet data to elements using element.constructor.dataKey
  syncExternalDataFrom(data) {
    for (const element of this.engine.state.elements) {
      const instance = this.engine.canvases.getInstanceById(element.id || element.name)
      if (!instance) continue

      const dataKey = instance.constructor.dataKey
      if (!dataKey) continue

      const value = data[dataKey]
      if (value === undefined || value === null) continue

      // QR elements use setImageData/loadImage, text elements use text property
      if (instance.setImageData) {
        instance.setImageData(value)
      } else if (instance.loadImage) {
        instance.loadImage(value)
      } else {
        // Text element
        this.engine.updateElement(element.id || element.name, { text: value })
        instance.text = value
      }
    }

    this.engine.scheduleRender()
  }

  // Listen for external data changes (bitcoin:changed event)
  dataSourceChanged(event) {
    const data = event?.detail
    if (!data) return

    // Persist to hidden field so syncExternalData works after theme changes
    // Note: dataSource field is disabled so it's never submitted to server
    if (this.hasDataSourceTarget) {
      this.dataSourceTarget.value = JSON.stringify(data)
    }

    this.syncExternalDataFrom(data)
    this.engine.scheduleRender()
  }

  // --- Actions ---

  // Add new text element
  addText() {
    this.engine.addElement("text")
  }

  // Toggle between front and back
  toggleSide() {
    this.engine.toggleSide()
  }

  // Switch to specific side (called from tabs controller)
  switchSide(event) {
    const side = event.currentTarget.dataset.tabId
    this.engine.setSide(side)
  }

  // Delete selected element
  deleteSelected() {
    this.engine.deleteSelected()
  }

  // Move selected to other side
  moveToOther() {
    this.engine.moveSelectedToOtherSide()
  }

  // Copy selected to other side
  copyToOther() {
    this.engine.copySelectedToOtherSide()
  }

  // Export both sides
  async exportBoth() {
    await this.exporter.downloadBoth('hongbao')
  }

  // Export combined
  async exportCombined() {
    await this.exporter.downloadCombined('hongbao.png', 'vertical')
  }

  // --- Theme Integration ---

  // Handle theme change (called from theme selector)
  async loadTheme(event) {
    const { themeId, frontUrl, backUrl, elements, aspectRatio, layoutDirection, cssClasses, rotationBack, foldLine, layoutClasses } = event.detail

    this.themeIdValue = themeId

    // Store all frame data for export to preview
    if (layoutDirection) {
      this.currentFrameData = { aspectRatio, layoutDirection, cssClasses, rotationBack, foldLine, layoutClasses }
      this.updateLayout(layoutDirection, aspectRatio)
    }

    // Load theme and wait for backgrounds
    await this.engine.loadTheme({ frontUrl, backUrl, elements })

    // Update hidden img sources with the background URLs (for E2E test verification)
    // DOM-based engine stores the URL directly instead of converting to base64
    if (this.hasFrontBackgroundTarget && frontUrl) {
      this.frontBackgroundTarget.src = frontUrl
    }
    if (this.hasBackBackgroundTarget && backUrl) {
      this.backBackgroundTarget.src = backUrl
    }

    // Update thumbnails
    if (this.hasFrontThumbnailTarget && frontUrl) {
      this.frontThumbnailTarget.style.backgroundImage = `url('${frontUrl}')`
    }
    if (this.hasBackThumbnailTarget && backUrl) {
      this.backThumbnailTarget.style.backgroundImage = `url('${backUrl}')`
    }

    // Re-sync external data after theme change
    this.syncExternalData()
  }

  // Update container layout when frame orientation changes
  updateLayout(layoutDirection, aspectRatio) {
    // Update wrapper aspect ratio when theme changes
    ;[this.frontWrapperTarget, this.backWrapperTarget].forEach(wrapper => {
      if (!wrapper) return
      wrapper.style.aspectRatio = aspectRatio
    })
  }

  // Handle AI-generated image update (from Turbo Stream broadcast)
  updateImage(event) {
    const url = event.detail?.url
    if (!url) return

    // Find the image element in current state
    const imageElement = this.engine.state.elements.find(el => el.type === 'image')
    if (!imageElement) return

    // Get the element instance and load the new image
    const instance = this.engine.canvases.getInstanceById(imageElement.id || imageElement.name)
    if (instance?.loadImage) {
      instance.loadImage(url)
      this.engine.scheduleRender()
    }
  }

  // --- Persistence ---

  persistToField() {
    if (!this.hasFieldTarget) return

    // Serialize state in object format for Rails
    // Always save all elements - they define positions, not wallet data
    const state = this.engine.state.serialize({
      objectFormat: true
    })

    this.fieldTarget.value = JSON.stringify(state)

    // Dispatch event for other controllers
    this.dispatch("changed", { detail: { elements: state } })
  }

  // --- UI Updates ---

  handleSelectionChange(element) {
    // Dispatch event for property panels
    this.dispatch("select", {
      detail: {
        element,
        instance: element
          ? this.engine.canvases.getInstanceById(element.id || element.name)
          : null
      }
    })
  }

  updateSideUI(side) {
    if (this.hasSideToggleTarget) {
      this.sideToggleTarget.textContent = side.charAt(0).toUpperCase() + side.slice(1)
    }

    // Update wrapper visibility if in single view mode
    if (this.hasFrontWrapperTarget && this.hasBackWrapperTarget) {
      const isSingleView = this.element.classList.contains('single-view')
      if (isSingleView) {
        this.frontWrapperTarget.hidden = side !== 'front'
        this.backWrapperTarget.hidden = side !== 'back'
      }
    }

    // Update active state on wrappers
    this.frontWrapperTarget?.classList.toggle('active', side === 'front')
    this.backWrapperTarget?.classList.toggle('active', side === 'back')
  }

  openDrawerForElement(element) {
    if (!element) return

    // Get drawer from element class
    const instance = this.engine.canvases.getInstanceById(element.id || element.name)
    const drawerId = instance?.constructor?.drawer
    if (!drawerId) return

    const dialog = document.getElementById(drawerId)
    if (!dialog) return

    // Use Stimulus dispatch - events bubble to window by default
    // Each drawer controller filters by element type
    this.dispatch("drawerOpen", {
      detail: {
        element: structuredClone(element),
        elementId: element.id || element.name,
        engine: this.engine
      },
      bubbles: true
    })

    dialog.showModal()
  }

  // --- View Mode ---

  showSingle() {
    this.element.classList.add('single-view')
    this.updateSideUI(this.engine.activeSide)
  }

  showDual() {
    this.element.classList.remove('single-view')
    if (this.hasFrontWrapperTarget) this.frontWrapperTarget.hidden = false
    if (this.hasBackWrapperTarget) this.backWrapperTarget.hidden = false
  }

  // --- Keyboard Shortcuts ---

  keydown(event) {
    // Only handle if no input is focused
    if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') return

    switch (event.key) {
      case 'Delete':
      case 'Backspace':
        event.preventDefault()
        this.deleteSelected()
        break
      case 'Escape':
        this.engine.selection.clear()
        this.engine.scheduleRender()
        this.handleSelectionChange(null)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.nudgeSelected(0, event.shiftKey ? -10 : -1)
        break
      case 'ArrowDown':
        event.preventDefault()
        this.nudgeSelected(0, event.shiftKey ? 10 : 1)
        break
      case 'ArrowLeft':
        event.preventDefault()
        this.nudgeSelected(event.shiftKey ? -10 : -1, 0)
        break
      case 'ArrowRight':
        event.preventDefault()
        this.nudgeSelected(event.shiftKey ? 10 : 1, 0)
        break
    }
  }

  nudgeSelected(dx, dy) {
    const selected = this.engine.selection.current
    if (!selected) return

    this.engine.updateElement(selected.id || selected.name, {
      x: selected.x + dx,
      y: selected.y + dy
    })
  }
}
