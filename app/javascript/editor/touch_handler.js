// Unified touch/mouse handler for editor interactions
export class TouchHandler {
  constructor(element, callbacks = {}) {
    this.element = element
    this.callbacks = callbacks

    // Desktop: drag selects immediately (no click-to-select required)
    // Mobile: requires tap-to-select first for better UX
    this.directDrag = !this.isTouchDevice()

    // Touch state
    this.touches = new Map()

    // Drag state
    this.isDragging = false
    this.dragStart = null

    // Pinch state
    this.isPinching = false
    this.pinchStart = null

    // Bind event handlers
    this.boundHandlers = {
      pointerDown: this.onPointerDown.bind(this),
      pointerMove: this.onPointerMove.bind(this),
      pointerUp: this.onPointerUp.bind(this),
      pointerCancel: this.onPointerUp.bind(this),
      click: this.onClick.bind(this),
      dblclick: this.onDblClick.bind(this),
      touchStart: this.onTouchStart.bind(this),
      touchMove: this.onTouchMove.bind(this),
      touchEnd: this.onTouchEnd.bind(this)
    }

    this.bindEvents()
  }

  bindEvents() {
    // Pointer events for drag
    this.element.addEventListener('pointerdown', this.boundHandlers.pointerDown)
    document.addEventListener('pointermove', this.boundHandlers.pointerMove)
    document.addEventListener('pointerup', this.boundHandlers.pointerUp)
    document.addEventListener('pointercancel', this.boundHandlers.pointerCancel)

    // Native click/dblclick - browser handles timing
    this.element.addEventListener('click', this.boundHandlers.click)
    this.element.addEventListener('dblclick', this.boundHandlers.dblclick)

    // Touch events for multi-touch (pinch/rotate)
    this.element.addEventListener('touchstart', this.boundHandlers.touchStart, { passive: false })
    this.element.addEventListener('touchmove', this.boundHandlers.touchMove, { passive: false })
    this.element.addEventListener('touchend', this.boundHandlers.touchEnd)
  }

  destroy() {
    this.element.removeEventListener('pointerdown', this.boundHandlers.pointerDown)
    document.removeEventListener('pointermove', this.boundHandlers.pointerMove)
    document.removeEventListener('pointerup', this.boundHandlers.pointerUp)
    document.removeEventListener('pointercancel', this.boundHandlers.pointerCancel)

    this.element.removeEventListener('click', this.boundHandlers.click)
    this.element.removeEventListener('dblclick', this.boundHandlers.dblclick)

    this.element.removeEventListener('touchstart', this.boundHandlers.touchStart)
    this.element.removeEventListener('touchmove', this.boundHandlers.touchMove)
    this.element.removeEventListener('touchend', this.boundHandlers.touchEnd)
  }

  // Get point relative to element
  getPoint(event) {
    return {
      x: event.clientX,
      y: event.clientY
    }
  }

  // Pointer events (mouse + single touch)
  onPointerDown(event) {
    // Skip if multi-touch is happening
    if (this.isPinching) return

    // Don't preventDefault here - it blocks click events on mobile
    // We preventDefault in onPointerMove when actually dragging

    const point = this.getPoint(event)

    // Desktop: trigger selection before drag (reuses existing tap logic)
    if (this.directDrag) {
      this.callbacks.onTap?.(point)
    }

    this.dragStart = point
    this.callbacks.onDragStart?.(point)
    this.isDragging = true
  }

  onPointerMove(event) {
    const point = this.getPoint(event)

    // Hover (no button pressed)
    if (!this.isDragging) {
      this.callbacks.onHover?.(point)
      return
    }

    // Prevent scroll during drag on touch devices
    event.preventDefault()

    // Skip if pinching
    if (this.isPinching) return

    if (this.dragStart) {
      const dx = point.x - this.dragStart.x
      const dy = point.y - this.dragStart.y

      this.callbacks.onDrag?.({
        x: point.x,
        y: point.y,
        dx,
        dy,
        startX: this.dragStart.x,
        startY: this.dragStart.y
      })

      this.dragStart = point
    }
  }

  onPointerUp(event) {
    const point = this.getPoint(event)

    if (this.isDragging) {
      this.callbacks.onDragEnd?.(point)
    }

    this.isDragging = false
    this.dragStart = null
  }

  // Native click - browser handles tap detection
  onClick(event) {
    const point = this.getPoint(event)
    this.callbacks.onTap?.(point)
  }

  // Native dblclick - browser handles double-tap detection
  onDblClick(event) {
    const point = this.getPoint(event)
    this.callbacks.onDoubleTap?.(point)
  }

  // Touch events for multi-touch
  onTouchStart(event) {
    // Update touch map
    for (const touch of event.changedTouches) {
      this.touches.set(touch.identifier, {
        x: touch.clientX,
        y: touch.clientY
      })
    }

    // Start pinch if 2 touches
    if (this.touches.size === 2) {
      event.preventDefault()
      this.isPinching = true
      this.isDragging = false

      const [t1, t2] = Array.from(this.touches.values())
      this.pinchStart = {
        distance: this.distance(t1, t2),
        angle: this.angle(t1, t2),
        center: this.center(t1, t2)
      }

      this.callbacks.onPinchStart?.(this.pinchStart)
    }
  }

  onTouchMove(event) {
    // Update touch positions
    for (const touch of event.changedTouches) {
      this.touches.set(touch.identifier, {
        x: touch.clientX,
        y: touch.clientY
      })
    }

    // Handle pinch
    if (this.isPinching && this.touches.size === 2) {
      event.preventDefault()

      const [t1, t2] = Array.from(this.touches.values())
      const currentDistance = this.distance(t1, t2)
      const currentAngle = this.angle(t1, t2)
      const currentCenter = this.center(t1, t2)

      const scale = currentDistance / this.pinchStart.distance
      const rotation = currentAngle - this.pinchStart.angle

      this.callbacks.onPinch?.({
        scale,
        rotation,
        center: currentCenter,
        deltaX: currentCenter.x - this.pinchStart.center.x,
        deltaY: currentCenter.y - this.pinchStart.center.y
      })
    }
  }

  onTouchEnd(event) {
    // Remove ended touches
    for (const touch of event.changedTouches) {
      this.touches.delete(touch.identifier)
    }

    // End pinch
    if (this.isPinching && this.touches.size < 2) {
      this.isPinching = false
      this.pinchStart = null
      this.callbacks.onPinchEnd?.()
    }
  }

  // Utility: distance between two points
  distance(p1, p2) {
    return Math.hypot(p2.x - p1.x, p2.y - p1.y)
  }

  // Utility: angle between two points (degrees)
  angle(p1, p2) {
    return Math.atan2(p2.y - p1.y, p2.x - p1.x) * 180 / Math.PI
  }

  // Utility: center point between two points
  center(p1, p2) {
    return {
      x: (p1.x + p2.x) / 2,
      y: (p1.y + p2.y) / 2
    }
  }

  // Detect touch-capable device
  isTouchDevice() {
    return 'ontouchstart' in window || navigator.maxTouchPoints > 0
  }
}
