import { Controller } from "@hotwired/stimulus"

// Editor controller - orchestrates canvas item interactions
// Delegates to child controllers: overlay, resize, rotate
// Mobile: tap to select, drag to move, pinch to resize/rotate
// Desktop: hover shows border, click to select (shows handles), edit button opens drawer
export default class extends Controller {
  static targets = ["canvas", "elementsField", "hoverOverlay", "hoverLabel", "selectionOverlay", "selectionLabel"]
  static values = {
    enabled: { type: Boolean, default: true }
  }

  connect() {
    this.selectedItem = null
    this.hoveredItem = null
    this.isDragging = false
    this.dragStart = null
    this._canvaController = null
    this._overlayController = null
    this._rotateController = null

    requestAnimationFrame(() => {
      this.findCanvaController()
      this.findChildControllers()
      if (this._canvaController && this.enabledValue) {
        this.setupEvents()
      }
    })
  }

  disconnect() {
    this.removeEvents()
  }

  // --- Setup ---

  findCanvaController() {
    const canvaElement = this.element.querySelector('[data-controller~="canva"]')
    if (canvaElement) {
      this._canvaController = this.application.getControllerForElementAndIdentifier(canvaElement, 'canva')
    }
  }

  findChildControllers() {
    // Find overlay controller within this editor's scope
    const overlayElement = this.element.querySelector('[data-controller~="editor--overlay"]')
    if (overlayElement) {
      this._overlayController = this.application.getControllerForElementAndIdentifier(overlayElement, 'editor--overlay')
    }

    // Find rotate controller within this editor's scope
    const rotateElement = this.element.querySelector('[data-controller~="editor--rotate"]')
    if (rotateElement) {
      this._rotateController = this.application.getControllerForElementAndIdentifier(rotateElement, 'editor--rotate')
    }
  }

  get canvaController() {
    return this._canvaController
  }

  get canvasElement() {
    return this._canvaController?.containerTarget
  }

  get canvasWidth() {
    return this.canvaController?.originalWidth || 1
  }

  get canvasHeight() {
    return this.canvaController?.originalHeight || 1
  }

  isTouchDevice() {
    return 'ontouchstart' in window || navigator.maxTouchPoints > 0
  }

  // --- Events Setup ---

  setupEvents() {
    if (!this.canvasElement) return

    // Pointer events (mouse + touch)
    this.boundOnPointerDown = this.onPointerDown.bind(this)
    this.boundOnPointerMove = this.onPointerMove.bind(this)
    this.boundOnPointerUp = this.onPointerUp.bind(this)
    this.boundOnDocumentClick = this.onDocumentClick.bind(this)
    this.canvasElement.addEventListener("pointerdown", this.boundOnPointerDown)
    document.addEventListener("pointermove", this.boundOnPointerMove)
    document.addEventListener("pointerup", this.boundOnPointerUp)
    document.addEventListener("pointerdown", this.boundOnDocumentClick)

    // Touch events (pinch/rotate)
    this.boundOnTouchStart = this.onTouchStart.bind(this)
    this.boundOnTouchMove = this.onTouchMove.bind(this)
    this.boundOnTouchEnd = this.onTouchEnd.bind(this)
    this.canvasElement.addEventListener("touchstart", this.boundOnTouchStart, { passive: false })
    this.canvasElement.addEventListener("touchmove", this.boundOnTouchMove, { passive: false })
    this.canvasElement.addEventListener("touchend", this.boundOnTouchEnd)

    // Keyboard events
    this.boundOnKeyDown = this.onKeyDown.bind(this)
    document.addEventListener("keydown", this.boundOnKeyDown)

    // Hover events (desktop only)
    if (!this.isTouchDevice()) {
      this.boundOnHoverMove = this.onHoverMove.bind(this)
      this.boundOnHoverLeave = this.onHoverLeave.bind(this)
      this.canvasElement.addEventListener("pointermove", this.boundOnHoverMove)
      this.canvasElement.addEventListener("pointerleave", this.boundOnHoverLeave)
    }

  }

  removeEvents() {
    this.canvasElement?.removeEventListener("pointerdown", this.boundOnPointerDown)
    document.removeEventListener("pointermove", this.boundOnPointerMove)
    document.removeEventListener("pointerup", this.boundOnPointerUp)
    document.removeEventListener("pointerdown", this.boundOnDocumentClick)

    this.canvasElement?.removeEventListener("touchstart", this.boundOnTouchStart)
    this.canvasElement?.removeEventListener("touchmove", this.boundOnTouchMove)
    this.canvasElement?.removeEventListener("touchend", this.boundOnTouchEnd)

    document.removeEventListener("keydown", this.boundOnKeyDown)

    this.canvasElement?.removeEventListener("pointermove", this.boundOnHoverMove)
    this.canvasElement?.removeEventListener("pointerleave", this.boundOnHoverLeave)
  }

  // --- Pointer Events ---

  onPointerDown(e) {
    if (e.pointerType === "touch" && e.isPrimary === false) return

    const point = this.canvasPoint(e)
    const item = this.hitTest(point)
    const isMobile = e.pointerType === "touch"

    this.clickStart = { x: e.clientX, y: e.clientY, item, isMobile }

    if (item) {
      // On desktop: select item (shows handles)
      // On mobile: just track for drag, don't show selection UI
      if (!isMobile) {
        this.selectItem(item)
      } else {
        // Mobile: track selected item for drag/pinch but don't show overlay
        this.selectedItem = item
      }
      this.startDrag(item, point, e)
    } else {
      this.deselectAll()
    }
  }

  onPointerMove(e) {
    if (!this.isDragging || !this.selectedItem) return

    e.preventDefault()
    const point = this.canvasPoint(e)

    const dx = (point.x - this.dragStart.x) / this.canvasWidth * 100
    const dy = (point.y - this.dragStart.y) / this.canvasHeight * 100

    const newX = Math.max(0, Math.min(100 - this.selectedItem.widthValue, this.dragStart.itemX + dx))
    const newY = Math.max(0, Math.min(100 - this.selectedItem.heightValue, this.dragStart.itemY + dy))

    this.selectedItem.updatePosition(newX, newY)
    this.updateOverlay()
    this.canvaController.scheduleRedraw()
  }

  onPointerUp(e) {
    // Check if this was a click (minimal movement) vs drag
    if (this.clickStart?.item) {
      const dx = Math.abs(e.clientX - this.clickStart.x)
      const dy = Math.abs(e.clientY - this.clickStart.y)
      const isClick = dx < 5 && dy < 5

      if (isClick) {
        // Dispatch click event
        this.dispatch("itemClick", {
          detail: {
            name: this.clickStart.item.nameValue,
            type: this.clickStart.item.element.dataset.controller,
            controller: this.clickStart.item
          }
        })

        // On mobile: tap opens drawer directly (no selection UI)
        if (this.clickStart.isMobile) {
          this.clickStart.item.openDrawer()
          this.selectedItem = null // Clear selection after opening drawer
        }
      }
    }

    if (this.isDragging) {
      this.isDragging = false
      this.canvaController.redrawAll()
      this.persistChanges()

      // On mobile, clear selection after drag (no persistent selection)
      if (this.clickStart?.isMobile) {
        this.selectedItem = null
      }
    }

    this.clickStart = null
  }

  startDrag(item, point, e) {
    this.isDragging = true
    this.dragStart = {
      x: point.x,
      y: point.y,
      itemX: item.xValue,
      itemY: item.yValue
    }
    e.preventDefault()
  }

  // Handle clicks outside the editor area to deselect
  onDocumentClick(e) {
    if (!this.selectedItem) return

    // Check if click is inside the editor element (canvas + overlays)
    if (this.element.contains(e.target)) return

    // Click was outside - deselect
    this.deselectAll()
  }

  // --- Hover Events (Desktop - Figma/Canva style) ---
  // Hover shows border only, click shows handles

  onHoverMove(e) {
    if (this.isDragging || this.isResizing || this.isRotating || this.isPinching) return
    if (e.pointerType === "touch") return

    const point = this.canvasPoint(e)
    const item = this.hitTest(point)

    // Update hover state (border only, not handles)
    if (item !== this.hoveredItem) {
      this.hoveredItem = item

      if (item && item !== this.selectedItem) {
        this.showHoverOverlay(item)
      } else {
        this.hideHoverOverlay()
      }
    }
  }

  onHoverLeave(e) {
    if (this.isDragging || this.isResizing || this.isRotating || this.isPinching) return
    if (e.pointerType === "touch") return

    this.hoveredItem = null
    this.hideHoverOverlay()
  }

  // --- Touch Events (Pinch/Rotate) ---

  onTouchStart(e) {
    if (e.touches.length === 2 && this.selectedItem) {
      e.preventDefault()
      this.startPinch(e)
    }
  }

  onTouchMove(e) {
    if (e.touches.length === 2 && this.isPinching && this.selectedItem) {
      e.preventDefault()
      this.handlePinch(e)
    }
  }

  onTouchEnd() {
    if (this.isPinching) {
      this.isPinching = false
      this.persistChanges()
    }
  }

  startPinch(e) {
    this.isPinching = true
    const [t1, t2] = [e.touches[0], e.touches[1]]

    this.pinchStart = {
      distance: Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY),
      angle: Math.atan2(t2.clientY - t1.clientY, t2.clientX - t1.clientX) * 180 / Math.PI,
      width: this.selectedItem.widthValue,
      height: this.selectedItem.heightValue,
      rotation: this.selectedItem.rotationValue,
      fontSize: this.selectedItem.fontSizeValue
    }
  }

  handlePinch(e) {
    const [t1, t2] = [e.touches[0], e.touches[1]]
    const currentDistance = Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY)
    const currentAngle = Math.atan2(t2.clientY - t1.clientY, t2.clientX - t1.clientX) * 180 / Math.PI

    const scale = currentDistance / this.pinchStart.distance
    const rotation = currentAngle - this.pinchStart.angle

    const newWidth = Math.max(5, Math.min(100, this.pinchStart.width * scale))
    const newHeight = Math.max(5, Math.min(100, this.pinchStart.height * scale))

    const isTextItem = this.pinchStart.fontSize !== undefined && this.selectedItem.fontSizeValue !== undefined
    if (isTextItem) {
      const fontScale = 1 + (scale - 1) * 2  // 2x more responsive
      this.selectedItem.fontSizeValue = Math.max(0.5, this.pinchStart.fontSize * fontScale)
      this.selectedItem.widthValue = newWidth
    } else {
      this.selectedItem.updateSize(newWidth, newHeight)
    }

    this.selectedItem.rotationValue = this.pinchStart.rotation + rotation
    this.canvaController.scheduleRedraw()

    if (isTextItem && this.selectedItem.getCalculatedHeight) {
      requestAnimationFrame(() => {
        if (this.selectedItem?.getCalculatedHeight) {
          this.selectedItem.heightValue = this.selectedItem.getCalculatedHeight()
          this.updateOverlay()
        }
      })
    } else {
      this.updateOverlay()
    }
  }

  // --- Keyboard Events ---

  onKeyDown(e) {
    if (!this.selectedItem) return

    if ((e.key === "Delete" || e.key === "Backspace") && !this.selectedItem.presenceValue) {
      e.preventDefault()
      this.deleteSelected()
      return
    }

    if (e.key === "Escape") {
      this.deselectAll()
      return
    }

    // Enter or E to edit (open drawer)
    if (e.key === "Enter" || e.key === "e") {
      e.preventDefault()
      this.editSelected()
      return
    }

    const nudge = e.shiftKey ? 5 : 1
    let dx = 0, dy = 0

    switch (e.key) {
      case "ArrowUp": dy = -nudge; break
      case "ArrowDown": dy = nudge; break
      case "ArrowLeft": dx = -nudge; break
      case "ArrowRight": dx = nudge; break
      default: return
    }

    e.preventDefault()
    const newX = Math.max(0, Math.min(100 - this.selectedItem.widthValue, this.selectedItem.xValue + dx))
    const newY = Math.max(0, Math.min(100 - this.selectedItem.heightValue, this.selectedItem.yValue + dy))

    this.selectedItem.updatePosition(newX, newY)
    this.updateOverlay()
    this.canvaController.redrawAll()
    this.persistChanges()
  }

  // --- Resize Events (from resize controller) ---

  resizeStart(e) {
    this.isResizing = true
    if (!this.selectedItem || !this.canvasElement) return

    this.resizeData = {
      handle: e.detail.handle,
      startX: e.detail.clientX,
      startY: e.detail.clientY,
      width: this.selectedItem.widthValue,
      height: this.selectedItem.heightValue,
      itemX: this.selectedItem.xValue,
      itemY: this.selectedItem.yValue,
      fontSize: this.selectedItem.fontSizeValue
    }
  }

  resizeMove(e) {
    if (!this.isResizing || !this.selectedItem || !this.canvasElement) return

    const canvasRect = this.canvasElement.getBoundingClientRect()
    const dx = e.detail.dx / canvasRect.width * 100
    const dy = e.detail.dy / canvasRect.height * 100

    let { width, height, itemX, itemY } = this.resizeData
    let newWidth = width, newHeight = height, newX = itemX, newY = itemY

    switch (this.resizeData.handle) {
      case "se":
        newWidth = Math.max(5, width + dx)
        newHeight = Math.max(5, height + dy)
        break
      case "sw":
        newWidth = Math.max(5, width - dx)
        newHeight = Math.max(5, height + dy)
        newX = itemX + dx
        break
      case "ne":
        newWidth = Math.max(5, width + dx)
        newHeight = Math.max(5, height - dy)
        newY = itemY + dy
        break
      case "nw":
        newWidth = Math.max(5, width - dx)
        newHeight = Math.max(5, height - dy)
        newX = itemX + dx
        newY = itemY + dy
        break
    }

    this.selectedItem.updatePosition(newX, newY)

    const isTextItem = this.resizeData.fontSize !== undefined && this.selectedItem.fontSizeValue !== undefined
    if (isTextItem) {
      const scale = newWidth / this.resizeData.width
      const fontScale = 1 + (scale - 1) * 2  // 2x more responsive
      this.selectedItem.fontSizeValue = Math.max(0.5, this.resizeData.fontSize * fontScale)
      this.selectedItem.widthValue = newWidth
    } else {
      this.selectedItem.updateSize(newWidth, newHeight)
    }

    this.canvaController.scheduleRedraw()

    if (isTextItem && this.selectedItem.getCalculatedHeight) {
      requestAnimationFrame(() => {
        if (this.selectedItem?.getCalculatedHeight) {
          this.selectedItem.heightValue = this.selectedItem.getCalculatedHeight()
          this.updateOverlay()
        }
      })
    } else {
      this.updateOverlay()
    }
  }

  resizeEnd() {
    this.isResizing = false
    this.canvaController.redrawAll()

    if (this.selectedItem?.getCalculatedHeight) {
      this.selectedItem.heightValue = this.selectedItem.getCalculatedHeight()
      this.updateOverlay()
    }

    this.persistChanges()
  }

  // --- Rotate Events (from rotate controller) ---

  rotateStart() {
    this.isRotating = true
    if (!this.selectedItem || !this.canvasElement) return

    const bounds = this.selectedItem.getBounds()
    const canvasRect = this.canvasElement.getBoundingClientRect()
    const scaleX = canvasRect.width / this.canvasWidth
    const scaleY = canvasRect.height / this.canvasHeight

    const center = {
      x: canvasRect.left + (bounds.x + bounds.width / 2) * scaleX,
      y: canvasRect.top + (bounds.y + bounds.height / 2) * scaleY
    }

    this.rotateController?.setCenter(center, this.selectedItem.rotationValue)
  }

  rotateMove(e) {
    if (!this.isRotating || !this.selectedItem) return

    this.selectedItem.rotationValue = e.detail.rotation
    this.updateOverlay()
    this.canvaController.scheduleRedraw()
  }

  rotateEnd() {
    this.isRotating = false
    this.canvaController.redrawAll()
    this.persistChanges()
  }

  // --- Selection ---

  selectItem(itemController) {
    if (this.selectedItem && this.selectedItem !== itemController) {
      this.selectedItem.deselect()
    }

    this.selectedItem = itemController
    this.selectedItem.select()

    // Hide hover overlay, show selection overlay
    this.hideHoverOverlay()
    this.showSelectionOverlay(itemController)
  }

  deselectAll() {
    if (this.selectedItem) {
      this.selectedItem.deselect()
      this.selectedItem = null
    }
    this.hideSelectionOverlay()
  }

  // Edit button action - opens drawer for selected item
  editSelected() {
    if (!this.selectedItem) return
    this.selectedItem.openDrawer()
  }

  deleteSelected() {
    if (!this.selectedItem || this.selectedItem.presenceValue) return

    this.selectedItem.element.remove()
    this.selectedItem = null
    this.hideSelectionOverlay()
    this.canvaController.redrawAll()
    this.persistChanges()
  }

  // --- Hit Testing ---

  hitTest(point) {
    const items = this.getItemControllers()
    return items.reverse().find(item => item.containsPoint(point.x, point.y))
  }

  getItemControllers() {
    return this.canvaController?.canvaItemTargets?.map(el => {
      return this.canvaController.getItemController(el)
    }).filter(Boolean) || []
  }

  // --- Hover Overlay (border only) ---

  showHoverOverlay(item) {
    if (!this.hasHoverOverlayTarget || !item) return

    this.hoverOverlayTarget.classList.remove("hidden")
    this.updateOverlayPosition(this.hoverOverlayTarget, item)

    // Set label
    if (this.hasHoverLabelTarget) {
      this.hoverLabelTarget.textContent = this.getLabelForItem(item)
    }
  }

  hideHoverOverlay() {
    if (this.hasHoverOverlayTarget) {
      this.hoverOverlayTarget.classList.add("hidden")
    }
  }

  // --- Selection Overlay (border + handles) ---

  get overlayController() {
    return this._overlayController
  }

  get rotateController() {
    return this._rotateController
  }

  get canvasInfo() {
    if (!this.canvasElement) return null
    const canvasRect = this.canvasElement.getBoundingClientRect()
    return {
      scaleX: canvasRect.width / this.canvasWidth,
      scaleY: canvasRect.height / this.canvasHeight
    }
  }

  showSelectionOverlay(item) {
    this.overlayController?.show(item, this.canvasInfo)

    // Set label
    if (this.hasSelectionLabelTarget) {
      this.selectionLabelTarget.textContent = this.getLabelForItem(item)
    }
  }

  hideSelectionOverlay() {
    this.overlayController?.forceHide()
  }

  updateOverlay() {
    if (this.selectedItem) {
      this.overlayController?.updatePosition(this.selectedItem, this.canvasInfo)
    }
  }

  updateOverlayPosition(overlayEl, item) {
    if (!item || !this.canvasElement) return

    const bounds = item.getBounds()
    const { scaleX, scaleY } = this.canvasInfo

    overlayEl.style.left = `${bounds.x * scaleX}px`
    overlayEl.style.top = `${bounds.y * scaleY}px`
    overlayEl.style.width = `${bounds.width * scaleX}px`
    overlayEl.style.height = `${bounds.height * scaleY}px`

    if (item.rotationValue !== 0) {
      overlayEl.style.transform = `rotate(${item.rotationValue}deg)`
    } else {
      overlayEl.style.transform = ""
    }
  }

  // --- Utilities ---

  getLabelForItem(item) {
    if (!item) return ""
    // Humanize camelCase: "privateKeyQrcode" -> "Private Key Qrcode"
    const name = item.nameValue
    return name
      .replace(/([A-Z])/g, ' $1')  // Add space before capitals
      .replace(/^./, s => s.toUpperCase())  // Capitalize first letter
      .trim()
  }

  canvasPoint(e) {
    const canvas = this.canvasElement
    if (!canvas) return { x: 0, y: 0 }

    const rect = canvas.getBoundingClientRect()
    return {
      x: (e.clientX - rect.left) / rect.width * this.canvasWidth,
      y: (e.clientY - rect.top) / rect.height * this.canvasHeight
    }
  }

  // --- Persistence ---

  persistChanges() {
    const elements = {}
    this.getItemControllers().forEach(item => {
      const data = {
        x: item.xValue,
        y: item.yValue,
        width: item.widthValue,
        height: item.heightValue,
        rotation: item.rotationValue,
        presence: item.presenceValue,
        hidden: item.hiddenValue
      }
      if (item.fontSizeValue !== undefined) {
        data.font_size = item.fontSizeValue
      }
      elements[item.nameValue] = data
    })

    if (this.hasElementsFieldTarget) {
      this.elementsFieldTarget.value = JSON.stringify(elements)
    }

    this.dispatch("changed", { detail: { elements } })
  }
}
