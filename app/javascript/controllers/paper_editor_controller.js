import { Controller } from "@hotwired/stimulus"
import { Engine } from "../editor/engine"
import { Exporter } from "../editor/exporter"

// Domain-specific: maps element types to external data keys
// This is the ONLY place where app-specific data binding logic lives
const DATA_BINDINGS = {
  "private_key/text":       { prop: "text", dataKey: "private_key_text" },
  "private_key/qrcode":     { prop: "imageUrl", dataKey: "private_key_qrcode", isImage: true },
  "public_address/text":    { prop: "text", dataKey: "public_address_text" },
  "public_address/qrcode":  { prop: "imageUrl", dataKey: "public_address_qrcode", isImage: true },
  "mnemonic/text":          { prop: "text", dataKey: "mnemonic_text" }
}

// Paper editor controller - thin Stimulus bridge to the vanilla JS Engine
export default class extends Controller {
  static targets = [
    "frontCanvas",      // Front side canvas element
    "backCanvas",       // Back side canvas element
    "frontWrapper",     // Front canvas wrapper (for show/hide)
    "backWrapper",      // Back canvas wrapper (for show/hide)
    "field",            // Hidden input for elements JSON
    "dataSource",       // Hidden input for external data (e.g., wallet JSON)
    "sideToggle",       // Button showing current side
    "frontBackground",  // Hidden img for front background
    "backBackground"    // Hidden img for back background
  ]

  static values = {
    design: Object,     // Initial elements state from server
    themeId: String     // Current theme ID
  }

  connect() {
    console.log('[PaperEditor] connect() - designValue:', this.designValue)
    console.log('[PaperEditor] designValue type:', typeof this.designValue)
    console.log('[PaperEditor] designValue keys:', this.designValue ? Object.keys(this.designValue) : 'null')

    // Debug: Listen for bitcoin:changed event directly
    window.addEventListener('bitcoin:changed', (e) => {
      console.log('[PaperEditor] bitcoin:changed event received on window!', e.detail)
      this.syncExternalDataFrom(e.detail)
    })

    // Get background URLs
    const frontBackground = this.hasFrontBackgroundTarget
      ? this.frontBackgroundTarget.src
      : null
    const backBackground = this.hasBackBackgroundTarget
      ? this.backBackgroundTarget.src
      : null

    console.log('[PaperEditor] backgrounds - front:', frontBackground?.substring(0, 80), 'back:', backBackground?.substring(0, 80))

    // Initialize engine
    this.engine = new Engine(
      this.frontCanvasTarget,
      this.backCanvasTarget,
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

    // Create exporter
    this.exporter = new Exporter(this.engine.canvases, this.engine.state)

    // Enable debug mode to visualize element bounds (TODO: remove in production)
    this.engine.setDebug(true)

    // Start engine
    this.engine.start()

    // Sync initial external data
    this.syncExternalData()

    // Update UI
    this.updateSideUI(this.engine.activeSide)

    console.log('[PaperEditor] initialized successfully')
  }

  disconnect() {
    this.engine?.destroy()
  }

  // --- External Data Binding ---
  // Called on connect - tries to read from hidden field or wait for event
  syncExternalData() {
    if (!this.hasDataSourceTarget) {
      console.log('[PaperEditor] syncExternalData - no dataSourceTarget, waiting for bitcoin:changed event')
      return
    }

    const dataValue = this.dataSourceTarget.value
    if (!dataValue || dataValue === '{}') {
      console.log('[PaperEditor] syncExternalData - dataSource empty, waiting for bitcoin:changed event')
      return
    }

    try {
      const data = JSON.parse(dataValue)
      console.log('[PaperEditor] syncExternalData - from hidden field:', Object.keys(data))
      this.syncExternalDataFrom(data)
    } catch (e) {
      console.error('[PaperEditor] Failed to parse external data:', e)
    }
  }

  // Sync wallet data to elements
  syncExternalDataFrom(data) {
    console.log('[PaperEditor] syncExternalDataFrom - data keys:', Object.keys(data))

    for (const [type, binding] of Object.entries(DATA_BINDINGS)) {
      // Find element by type
      const element = this.engine.state.elements.find(e => e.type === type)
      if (!element) {
        console.log('[PaperEditor] element not found for type:', type)
        continue
      }

      const value = data[binding.dataKey]
      if (value === undefined || value === null) {
        console.log('[PaperEditor] no value for:', binding.dataKey)
        continue
      }

      console.log('[PaperEditor] syncing:', type, '← data key:', binding.dataKey, 'value length:', value?.length || 0)

      // Update element
      if (binding.isImage) {
        // For images, set via the element instance
        const instance = this.engine.canvases.getInstanceById(element.id || element.name)
        console.log('[PaperEditor] setting image for:', element.id, 'instance:', instance?.constructor?.name)
        if (instance?.setImageData) {
          instance.setImageData(value)
        } else if (instance?.loadImage) {
          instance.loadImage(value)
        }
      } else {
        // For text, update state and instance
        console.log('[PaperEditor] setting text for:', element.id, 'value:', value?.substring?.(0, 50) || value)
        this.engine.updateElement(element.id || element.name, {
          [binding.prop]: value
        })
        // Also update the instance directly
        const instance = this.engine.canvases.getInstanceById(element.id || element.name)
        if (instance) {
          instance[binding.prop] = value
        }
      }
    }

    this.engine.scheduleRender()
  }

  // Listen for external data changes (bitcoin:changed event)
  dataSourceChanged(event) {
    console.log('[PaperEditor] dataSourceChanged - event.detail:', event?.detail)

    // Get wallet data from event detail (dispatched by bitcoin controller)
    const data = event?.detail
    if (!data) {
      console.log('[PaperEditor] dataSourceChanged - no data in event.detail')
      return
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
  loadTheme(event) {
    const { themeId, frontUrl, backUrl, elements } = event.detail

    this.themeIdValue = themeId
    this.engine.loadTheme({ frontUrl, backUrl, elements })

    // Re-sync external data after theme change
    this.syncExternalData()
  }

  // --- Persistence ---

  persistToField() {
    if (!this.hasFieldTarget) return

    // Serialize state in object format for Rails
    const state = this.engine.state.serialize({
      excludeSensitive: true,
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

    // Dispatch event for drawer controllers to handle
    this.dispatch("edit", {
      detail: {
        element,
        instance: this.engine.canvases.getInstanceById(element.id || element.name),
        type: element.type
      }
    })
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
