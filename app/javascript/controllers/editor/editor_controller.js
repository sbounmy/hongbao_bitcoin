import { Controller } from "@hotwired/stimulus"

// Editor controller - orchestrates canvas item selection, drag, resize
// Mobile: tap to select, drag to move, pinch to resize/rotate
// Desktop: click to select, drag to move, handles for resize/rotate
export default class extends Controller {
  static targets = ["overlay", "elementsField"]
  static values = {
    enabled: { type: Boolean, default: true }
  }

  connect() {
    this.selectedItem = null
    this.isDragging = false
    this.dragStart = null

    // Find the canva controller within this editor (not using outlets to avoid cross-canvas issues)
    this._canvaController = null
    this._canvasElement = null

    // Wait a tick for child controllers to connect
    requestAnimationFrame(() => {
      this.findCanvaController()
      if (this._canvaController && this.enabledValue) {
        this.setupPointerEvents()
        this.setupTouchEvents()
        this.setupKeyboardEvents()
      }
    })
  }

  findCanvaController() {
    // Find the canva element within this editor's element
    const canvaElement = this.element.querySelector('[data-controller~="canva"]')
    if (canvaElement) {
      this._canvaController = this.application.getControllerForElementAndIdentifier(canvaElement, 'canva')
      this._canvasElement = this._canvaController?.containerTarget
    }
  }

  // Get the canva controller within this editor
  get canvaController() {
    return this._canvaController
  }

  // Get the canvas element from the canva controller
  get canvasElement() {
    return this._canvasElement
  }

  disconnect() {
    this.removePointerEvents()
    this.removeTouchEvents()
    this.removeKeyboardEvents()
  }

  // --- Pointer Events (unified mouse + touch) ---

  setupPointerEvents() {
    if (!this.canvasElement) return

    this.boundOnPointerDown = this.onPointerDown.bind(this)
    this.boundOnPointerMove = this.onPointerMove.bind(this)
    this.boundOnPointerUp = this.onPointerUp.bind(this)

    this.canvasElement.addEventListener("pointerdown", this.boundOnPointerDown)
    document.addEventListener("pointermove", this.boundOnPointerMove)
    document.addEventListener("pointerup", this.boundOnPointerUp)
  }

  removePointerEvents() {
    this.canvasElement?.removeEventListener("pointerdown", this.boundOnPointerDown)
    document.removeEventListener("pointermove", this.boundOnPointerMove)
    document.removeEventListener("pointerup", this.boundOnPointerUp)
  }

  onPointerDown(e) {
    // Ignore multi-touch (handled separately for pinch/rotate)
    if (e.pointerType === "touch" && e.isPrimary === false) return

    const point = this.canvasPoint(e)
    const item = this.hitTest(point)

    // Track click start position to detect click vs drag
    this.clickStart = { x: e.clientX, y: e.clientY, item }

    if (item) {
      this.selectItem(item)
      this.startDrag(item, point, e)
    } else {
      this.deselectAll()
    }
  }

  onPointerMove(e) {
    if (!this.isDragging || !this.selectedItem) return

    e.preventDefault()
    const point = this.canvasPoint(e)

    // Calculate delta in percentage
    const dx = (point.x - this.dragStart.x) / this.canvasWidth * 100
    const dy = (point.y - this.dragStart.y) / this.canvasHeight * 100

    // Update item position
    const newX = Math.max(0, Math.min(100 - this.selectedItem.widthValue, this.dragStart.itemX + dx))
    const newY = Math.max(0, Math.min(100 - this.selectedItem.heightValue, this.dragStart.itemY + dy))

    this.selectedItem.updatePosition(newX, newY)
    this.updateOverlayPosition()
    this.canvaController.scheduleRedraw()
  }

  onPointerUp(e) {
    // Check if this was a click (minimal movement) vs drag
    if (this.clickStart?.item) {
      const dx = Math.abs(e.clientX - this.clickStart.x)
      const dy = Math.abs(e.clientY - this.clickStart.y)
      const isClick = dx < 5 && dy < 5

      if (isClick) {
        // Dispatch click event for the item
        this.dispatch("itemClick", {
          detail: {
            name: this.clickStart.item.nameValue,
            type: this.clickStart.item.element.dataset.controller,
            controller: this.clickStart.item
          }
        })

        // Let the item handle opening its drawer
        this.clickStart.item.openDrawer()
      }
    }

    if (this.isDragging) {
      this.isDragging = false
      this.canvaController.redrawAll() // Final redraw to ensure clean state
      this.persistChanges()
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

    // Prevent text selection during drag
    e.preventDefault()
  }

  // --- Touch Events (for pinch/rotate gestures) ---

  setupTouchEvents() {
    if (!this.canvasElement) return

    this.boundOnTouchStart = this.onTouchStart.bind(this)
    this.boundOnTouchMove = this.onTouchMove.bind(this)
    this.boundOnTouchEnd = this.onTouchEnd.bind(this)

    this.canvasElement.addEventListener("touchstart", this.boundOnTouchStart, { passive: false })
    this.canvasElement.addEventListener("touchmove", this.boundOnTouchMove, { passive: false })
    this.canvasElement.addEventListener("touchend", this.boundOnTouchEnd)
  }

  removeTouchEvents() {
    this.canvasElement?.removeEventListener("touchstart", this.boundOnTouchStart)
    this.canvasElement?.removeEventListener("touchmove", this.boundOnTouchMove)
    this.canvasElement?.removeEventListener("touchend", this.boundOnTouchEnd)
  }

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

  onTouchEnd(e) {
    if (this.isPinching) {
      this.isPinching = false
      this.persistChanges()
    }
  }

  startPinch(e) {
    this.isPinching = true
    const touch1 = e.touches[0]
    const touch2 = e.touches[1]

    this.initialPinchDistance = this.getDistance(touch1, touch2)
    this.initialPinchAngle = this.getAngle(touch1, touch2)
    this.initialWidth = this.selectedItem.widthValue
    this.initialHeight = this.selectedItem.heightValue
    this.initialRotation = this.selectedItem.rotationValue
    // For text items, also capture font size to scale proportionally
    this.initialFontSize = this.selectedItem.fontSizeValue
  }

  handlePinch(e) {
    const touch1 = e.touches[0]
    const touch2 = e.touches[1]

    // Calculate scale from pinch
    const currentDistance = this.getDistance(touch1, touch2)
    const scale = currentDistance / this.initialPinchDistance

    // Calculate rotation
    const currentAngle = this.getAngle(touch1, touch2)
    const rotation = currentAngle - this.initialPinchAngle

    // Apply scale to dimensions
    const newWidth = Math.max(5, Math.min(100, this.initialWidth * scale))
    const newHeight = Math.max(5, Math.min(100, this.initialHeight * scale))

    // For text items, scale font size and auto-calculate height
    const isTextItem = this.initialFontSize !== undefined && this.selectedItem.fontSizeValue !== undefined
    if (isTextItem) {
      const newFontSize = Math.max(0.5, this.initialFontSize * scale)
      this.selectedItem.fontSizeValue = newFontSize
      this.selectedItem.widthValue = newWidth
      // Height will be auto-calculated after draw
    } else {
      this.selectedItem.updateSize(newWidth, newHeight)
    }

    this.selectedItem.rotationValue = this.initialRotation + rotation
    this.canvaController.scheduleRedraw()

    // For text items, use calculated height after draw (on next frame)
    if (isTextItem && this.selectedItem.getCalculatedHeight) {
      requestAnimationFrame(() => {
        if (this.selectedItem?.getCalculatedHeight) {
          this.selectedItem.heightValue = this.selectedItem.getCalculatedHeight()
          this.updateOverlayPosition()
        }
      })
    } else {
      this.updateOverlayPosition()
    }
  }

  getDistance(t1, t2) {
    return Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY)
  }

  getAngle(t1, t2) {
    return Math.atan2(t2.clientY - t1.clientY, t2.clientX - t1.clientX) * 180 / Math.PI
  }

  // --- Keyboard Events ---

  setupKeyboardEvents() {
    this.boundOnKeyDown = this.onKeyDown.bind(this)
    document.addEventListener("keydown", this.boundOnKeyDown)
  }

  removeKeyboardEvents() {
    document.removeEventListener("keydown", this.boundOnKeyDown)
  }

  onKeyDown(e) {
    if (!this.selectedItem) return

    // Delete/Backspace to delete (if not presence item)
    if ((e.key === "Delete" || e.key === "Backspace") && !this.selectedItem.presenceValue) {
      e.preventDefault()
      this.deleteSelected()
      return
    }

    // Escape to deselect
    if (e.key === "Escape") {
      this.deselectAll()
      return
    }

    // Arrow keys to nudge
    const nudgeAmount = e.shiftKey ? 5 : 1 // Shift for larger nudge
    let dx = 0, dy = 0

    switch (e.key) {
      case "ArrowUp": dy = -nudgeAmount; break
      case "ArrowDown": dy = nudgeAmount; break
      case "ArrowLeft": dx = -nudgeAmount; break
      case "ArrowRight": dx = nudgeAmount; break
      default: return
    }

    e.preventDefault()
    const newX = Math.max(0, Math.min(100 - this.selectedItem.widthValue, this.selectedItem.xValue + dx))
    const newY = Math.max(0, Math.min(100 - this.selectedItem.heightValue, this.selectedItem.yValue + dy))

    this.selectedItem.updatePosition(newX, newY)
    this.updateOverlayPosition()
    this.canvaController.redrawAll()
    this.persistChanges()
  }

  // --- Selection ---

  selectItem(itemController) {
    // Deselect previous
    if (this.selectedItem && this.selectedItem !== itemController) {
      this.selectedItem.deselect()
    }

    this.selectedItem = itemController
    this.selectedItem.select()
    this.showOverlay()
  }

  deselectAll() {
    if (this.selectedItem) {
      this.selectedItem.deselect()
      this.selectedItem = null
    }
    this.hideOverlay()
  }

  deleteSelected() {
    if (!this.selectedItem || this.selectedItem.presenceValue) return

    // Remove the item element
    this.selectedItem.element.remove()
    this.selectedItem = null
    this.hideOverlay()
    this.canvaController.redrawAll()
    this.persistChanges()
  }

  // --- Hit Testing ---

  hitTest(point) {
    const items = this.getItemControllers()
    // Reverse to check topmost items first
    return items.reverse().find(item => item.containsPoint(point.x, point.y))
  }

  getItemControllers() {
    return this.canvaController.canvaItemTargets.map(el => {
      return this.canvaController.getItemController(el)
    }).filter(Boolean)
  }

  // --- Overlay ---

  showOverlay() {
    if (!this.hasOverlayTarget || !this.selectedItem) return

    this.overlayTarget.classList.remove("hidden")
    this.updateOverlayPosition()

    // Show/hide delete button based on presence
    const deleteBtn = this.overlayTarget.querySelector("[data-delete-btn]")
    if (deleteBtn) {
      deleteBtn.classList.toggle("hidden", this.selectedItem.presenceValue)
    }
  }

  hideOverlay() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
  }

  updateOverlayPosition() {
    if (!this.hasOverlayTarget || !this.selectedItem || !this.canvasElement) return

    const bounds = this.selectedItem.getBounds()
    const canvas = this.canvasElement
    const canvasRect = canvas.getBoundingClientRect()

    // Convert canvas coordinates to screen coordinates
    const scaleX = canvasRect.width / this.canvasWidth
    const scaleY = canvasRect.height / this.canvasHeight

    this.overlayTarget.style.left = `${bounds.x * scaleX}px`
    this.overlayTarget.style.top = `${bounds.y * scaleY}px`
    this.overlayTarget.style.width = `${bounds.width * scaleX}px`
    this.overlayTarget.style.height = `${bounds.height * scaleY}px`

    // Apply rotation if any
    if (this.selectedItem.rotationValue !== 0) {
      this.overlayTarget.style.transform = `rotate(${this.selectedItem.rotationValue}deg)`
    } else {
      this.overlayTarget.style.transform = ""
    }
  }

  // --- Resize Handles (Desktop) ---

  startResize(e) {
    const handle = e.currentTarget.dataset.handle
    this.isResizing = true
    this.resizeHandle = handle
    this.resizeStart = {
      x: e.clientX,
      y: e.clientY,
      width: this.selectedItem.widthValue,
      height: this.selectedItem.heightValue,
      itemX: this.selectedItem.xValue,
      itemY: this.selectedItem.yValue,
      // For text items, also capture font size to scale proportionally
      fontSize: this.selectedItem.fontSizeValue
    }

    document.addEventListener("pointermove", this.boundOnResizeMove = this.onResizeMove.bind(this))
    document.addEventListener("pointerup", this.boundOnResizeUp = this.onResizeUp.bind(this))

    e.preventDefault()
    e.stopPropagation()
  }

  onResizeMove(e) {
    if (!this.isResizing || !this.selectedItem || !this.canvasElement) return

    const canvas = this.canvasElement
    const canvasRect = canvas.getBoundingClientRect()

    // Calculate delta in percentage
    const dx = (e.clientX - this.resizeStart.x) / canvasRect.width * 100
    const dy = (e.clientY - this.resizeStart.y) / canvasRect.height * 100

    let newWidth = this.resizeStart.width
    let newHeight = this.resizeStart.height
    let newX = this.resizeStart.itemX
    let newY = this.resizeStart.itemY

    // Adjust based on which handle is being dragged
    switch (this.resizeHandle) {
      case "se": // Bottom-right
        newWidth = Math.max(5, this.resizeStart.width + dx)
        newHeight = Math.max(5, this.resizeStart.height + dy)
        break
      case "sw": // Bottom-left
        newWidth = Math.max(5, this.resizeStart.width - dx)
        newHeight = Math.max(5, this.resizeStart.height + dy)
        newX = this.resizeStart.itemX + dx
        break
      case "ne": // Top-right
        newWidth = Math.max(5, this.resizeStart.width + dx)
        newHeight = Math.max(5, this.resizeStart.height - dy)
        newY = this.resizeStart.itemY + dy
        break
      case "nw": // Top-left
        newWidth = Math.max(5, this.resizeStart.width - dx)
        newHeight = Math.max(5, this.resizeStart.height - dy)
        newX = this.resizeStart.itemX + dx
        newY = this.resizeStart.itemY + dy
        break
    }

    this.selectedItem.updatePosition(newX, newY)

    // For text items, scale font size and auto-calculate height
    const isTextItem = this.resizeStart.fontSize !== undefined && this.selectedItem.fontSizeValue !== undefined
    if (isTextItem) {
      const scale = newWidth / this.resizeStart.width
      const newFontSize = Math.max(0.5, this.resizeStart.fontSize * scale)
      this.selectedItem.fontSizeValue = newFontSize
      // Only update width for text - height will be auto-calculated after draw
      this.selectedItem.widthValue = newWidth
    } else {
      this.selectedItem.updateSize(newWidth, newHeight)
    }

    this.canvaController.scheduleRedraw()

    // For text items, use calculated height after draw (on next frame)
    if (isTextItem && this.selectedItem.getCalculatedHeight) {
      requestAnimationFrame(() => {
        if (this.selectedItem?.getCalculatedHeight) {
          this.selectedItem.heightValue = this.selectedItem.getCalculatedHeight()
          this.updateOverlayPosition()
        }
      })
    } else {
      this.updateOverlayPosition()
    }
  }

  onResizeUp() {
    this.isResizing = false
    document.removeEventListener("pointermove", this.boundOnResizeMove)
    document.removeEventListener("pointerup", this.boundOnResizeUp)

    // Final redraw and height adjustment for text items
    this.canvaController.redrawAll()
    if (this.selectedItem?.getCalculatedHeight) {
      this.selectedItem.heightValue = this.selectedItem.getCalculatedHeight()
      this.updateOverlayPosition()
    }

    this.persistChanges()
  }

  // --- Rotation Handle (Desktop) ---

  startRotate(e) {
    if (!this.canvasElement) return

    this.isRotating = true

    const bounds = this.selectedItem.getBounds()
    const canvas = this.canvasElement
    const canvasRect = canvas.getBoundingClientRect()

    // Center of the item in screen coordinates
    const scaleX = canvasRect.width / this.canvasWidth
    const scaleY = canvasRect.height / this.canvasHeight

    this.rotateCenter = {
      x: canvasRect.left + (bounds.x + bounds.width / 2) * scaleX,
      y: canvasRect.top + (bounds.y + bounds.height / 2) * scaleY
    }
    this.rotateStart = this.selectedItem.rotationValue

    document.addEventListener("pointermove", this.boundOnRotateMove = this.onRotateMove.bind(this))
    document.addEventListener("pointerup", this.boundOnRotateUp = this.onRotateUp.bind(this))

    e.preventDefault()
    e.stopPropagation()
  }

  onRotateMove(e) {
    if (!this.isRotating || !this.selectedItem) return

    const angle = Math.atan2(
      e.clientY - this.rotateCenter.y,
      e.clientX - this.rotateCenter.x
    ) * 180 / Math.PI

    // Offset by 90 degrees since handle is at top
    this.selectedItem.rotationValue = angle + 90

    this.updateOverlayPosition()
    this.canvaController.scheduleRedraw()
  }

  onRotateUp() {
    this.isRotating = false
    document.removeEventListener("pointermove", this.boundOnRotateMove)
    document.removeEventListener("pointerup", this.boundOnRotateUp)
    this.canvaController.redrawAll() // Final redraw
    this.persistChanges()
  }

  // --- Utilities ---

  canvasPoint(e) {
    const canvas = this.canvasElement
    if (!canvas) return { x: 0, y: 0 }

    const rect = canvas.getBoundingClientRect()

    // Convert screen coordinates to canvas coordinates
    return {
      x: (e.clientX - rect.left) / rect.width * this.canvasWidth,
      y: (e.clientY - rect.top) / rect.height * this.canvasHeight
    }
  }

  get canvasWidth() {
    return this.canvaController.originalWidth
  }

  get canvasHeight() {
    return this.canvaController.originalHeight
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
      // Include font_size for text items
      if (item.fontSizeValue !== undefined) {
        data.font_size = item.fontSizeValue
      }
      elements[item.nameValue] = data
    })

    // Update hidden field if present
    if (this.hasElementsFieldTarget) {
      this.elementsFieldTarget.value = JSON.stringify(elements)
    }

    // Dispatch event so other canvases (like PDF preview) can sync
    this.dispatch("changed", { detail: { elements } })
  }
}
