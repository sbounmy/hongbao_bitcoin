import { Controller } from "@hotwired/stimulus"
import html2canvas from 'html2canvas-pro'
import PDFDocument from 'pdfkit/js/pdfkit.standalone'
import blobStream from 'blob-stream'

export default class extends Controller {
  static targets = ["content", "viewport", "zoomDisplay", "wrapper", "password", "backdrop"]
  static values = {
    zoom: { type: Number, default: 0.8 },
    minZoom: { type: Number, default: 0.3 },
    maxZoom: { type: Number, default: 6.0 },
    zoomStep: { type: Number, default: 0.1 },
    wheelZoomSpeed: { type: Number, default: 0.01 },
    expanded: { type: Boolean, default: false }
  }

  connect() {
    this.lastZoom = this.zoomValue
    this.pendingCursorPosition = null
    this.initialPinchDistance = 0

    // Defer zoom setup until element is visible (has dimensions)
    this.resizeObserver = new ResizeObserver(() => {
      if (this.contentTarget.offsetWidth > 0 && !this.isInitialized) {
        this.isInitialized = true
        this.resizeObserver.disconnect()
        this.applyZoomTransform()
        this.updateZoomDisplay()
      }
    })
    this.resizeObserver.observe(this.contentTarget)
  }

  disconnect() {
    this.pendingCursorPosition = null
    this.resizeObserver?.disconnect()
  }

  zoomIn() {
    this.zoomValue = Math.min(this.maxZoomValue, this.zoomValue + this.zoomStepValue)
  }

  zoomOut() {
    this.zoomValue = Math.max(this.minZoomValue, this.zoomValue - this.zoomStepValue)
  }

  resetZoom() {
    this.zoomValue = 0.8
  }

  zoomValueChanged() {
    // This is called automatically by Stimulus whenever zoomValue changes
    this.updateZoom(this.pendingCursorPosition?.x, this.pendingCursorPosition?.y)
    this.pendingCursorPosition = null
  }

  updateZoom(cursorX = null, cursorY = null) {
    if (!this.hasContentTarget || !this.hasWrapperTarget || !this.hasViewportTarget) return

    const position = this.calculateCursorPosition(cursorX, cursorY)
    this.applyZoomTransform()
    this.adjustScrollForCursor(position, cursorX, cursorY)
    this.updateZoomDisplay()

    // Update lastZoom after the zoom has been applied
    this.lastZoom = this.zoomValue
  }

  calculateCursorPosition(cursorX, cursorY) {
    const viewport = this.viewportTarget
    const contentWidth = this.contentTarget.offsetWidth
    const contentHeight = this.contentTarget.offsetHeight
    const scrollLeft = viewport.scrollLeft
    const scrollTop = viewport.scrollTop

    // Default to center if no cursor position
    if (cursorX === null || cursorY === null) {
      return { relativeX: 0.5, relativeY: 0.5, viewportX: 0, viewportY: 0 }
    }

    // Get cursor position relative to viewport
    const rect = viewport.getBoundingClientRect()
    const viewportX = cursorX - rect.left
    const viewportY = cursorY - rect.top

    // Calculate the point on the content that the cursor is over
    const relativeX = (scrollLeft + viewportX) / (contentWidth * this.lastZoom)
    const relativeY = (scrollTop + viewportY) / (contentHeight * this.lastZoom)

    return { relativeX, relativeY, viewportX, viewportY }
  }

  applyZoomTransform() {
    const contentWidth = this.contentTarget.offsetWidth
    const contentHeight = this.contentTarget.offsetHeight

    // Scale the content from its top-left corner
    this.contentTarget.style.transform = `scale(${this.zoomValue})`

    // Resize the wrapper to the new scaled dimensions
    this.wrapperTarget.style.width = `${contentWidth * this.zoomValue}px`
    this.wrapperTarget.style.height = `${contentHeight * this.zoomValue}px`
  }

  adjustScrollForCursor(position, cursorX, cursorY) {
    if (cursorX === null || cursorY === null) return

    const viewport = this.viewportTarget
    const contentWidth = this.contentTarget.offsetWidth
    const contentHeight = this.contentTarget.offsetHeight
    const { relativeX, relativeY, viewportX, viewportY } = position

    // Calculate new scroll position to keep the cursor over the same content point
    const newScrollLeft = (relativeX * contentWidth * this.zoomValue) - viewportX
    const newScrollTop = (relativeY * contentHeight * this.zoomValue) - viewportY

    viewport.scrollLeft = Math.max(0, newScrollLeft)
    viewport.scrollTop = Math.max(0, newScrollTop)
  }

  updateZoomDisplay() {
    const percentage = Math.round(this.zoomValue * 100)
    // Update ALL zoomDisplay targets (one per step header)
    this.zoomDisplayTargets.forEach(target => {
      target.textContent = `${percentage}%`
    })
  }

   // Handles pinch-to-zoom on laptop trackpads.
  handleWheel(event) {
    if (event.ctrlKey) {
      event.preventDefault()

      // Store cursor position for the value change callback
      this.pendingCursorPosition = { x: event.clientX, y: event.clientY }

      const zoomFactor = this.zoomValue * this.wheelZoomSpeedValue;
      let newZoom = this.zoomValue - (event.deltaY * zoomFactor);

      // Set the new zoom value (clamping happens in the setter, triggers zoomValueChanged)
      this.zoomValue = Math.max(this.minZoomValue, Math.min(this.maxZoomValue, newZoom))
    }
  }
  // Pinch-to-zoom handlers
  handleTouchStart(event) {
    if (event.touches.length === 2) {
      event.preventDefault()
      this.initialPinchDistance = this.getDistance(event.touches)
      this.lastZoom = this.zoomValue
    }
  }

  handleTouchMove(event) {
    if (event.touches.length === 2) {
      event.preventDefault()
      const currentDistance = this.getDistance(event.touches)
      const scale = currentDistance / this.initialPinchDistance
      let newZoom = this.lastZoom * scale

      // Calculate center point of the two touches
      const touch1 = event.touches[0]
      const touch2 = event.touches[1]
      const centerX = (touch1.clientX + touch2.clientX) / 2
      const centerY = (touch1.clientY + touch2.clientY) / 2

      // Store cursor position for the value change callback
      this.pendingCursorPosition = { x: centerX, y: centerY }

      // Set the new zoom value (triggers zoomValueChanged)
      this.zoomValue = Math.max(this.minZoomValue, Math.min(this.maxZoomValue, newZoom))
    }
  }

  handleTouchEnd(event) {
    if (event.touches.length < 2) {
      this.lastZoom = this.zoomValue
    }
  }

  getDistance(touches) {
    const [touch1, touch2] = touches
    return Math.sqrt(
      Math.pow(touch2.clientX - touch1.clientX, 2) +
      Math.pow(touch2.clientY - touch1.clientY, 2)
    )
  }

  // Expand/Collapse functionality
  expand() {
    this.expandedValue = true
  }

  collapse() {
    this.expandedValue = false
  }

  toggle() {
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged() {
    if (this.expandedValue) {
      this.enterFullscreen()
    } else {
      this.exitFullscreen()
    }
  }

  // Called from viewport click action - only collapse if expanded
  handleViewportClick(event) {
    if (this.expandedValue) {
      event.preventDefault()
      event.stopPropagation()
      this.collapse()
    }
  }

  enterFullscreen() {
    // Store original max-height classes to restore later
    this.originalMaxHeightClasses = []
    this.viewportTarget.classList.forEach(cls => {
      if (cls.startsWith('max-h-') || cls.startsWith('md:max-h-')) {
        this.originalMaxHeightClasses.push(cls)
      }
    })
    // Remove max-height constraints
    this.originalMaxHeightClasses.forEach(cls => {
      this.viewportTarget.classList.remove(cls)
    })
    // Make viewport fullscreen and centered
    this.viewportTarget.classList.add(
      'fixed', 'inset-0', 'z-50',
      'flex', 'items-center', 'justify-center',
      'cursor-pointer', 'bg-black/80'
    )
    // Escape key listener
    this.escapeHandler = (e) => {
      if (e.key === 'Escape') this.collapse()
    }
    document.addEventListener('keydown', this.escapeHandler)
  }

  exitFullscreen() {
    // Remove fullscreen classes
    this.viewportTarget.classList.remove(
      'fixed', 'inset-0', 'z-50',
      'flex', 'items-center', 'justify-center',
      'cursor-pointer', 'bg-black/80'
    )
    // Restore original max-height classes
    if (this.originalMaxHeightClasses) {
      this.originalMaxHeightClasses.forEach(cls => {
        this.viewportTarget.classList.add(cls)
      })
    }
    // Remove event listeners
    if (this.escapeHandler) {
      document.removeEventListener('keydown', this.escapeHandler)
    }
  }

  async download(event) {
    event.preventDefault()

    // Loading state
    const button = event.currentTarget
    const originalHTML = button.innerHTML
    button.disabled = true
    button.innerHTML = '<span class="loading loading-spinner loading-sm"></span> Processing...'
    const resetButton = () => {
      button.innerHTML = originalHTML
      button.disabled = false
    }

    try {
      this.contentTarget.style.transform = '' // Remove zoom transform
      this.viewportTarget.scrollTop = 0       // Scroll to top
      this.viewportTarget.scrollLeft = 0      // Scroll to left
      // Convert content to canvas
      const canvas = await html2canvas(this.contentTarget, {
        scale: 3, // Higher quality
        useCORS: true, // Allow cross-origin images
        logging: false,
        scrollX: -window.scrollX, // negate scroll position to prevent clipping upon pdf download
        scrollY: -window.scrollY
      })

      // Get password if available
      const password = this.hasPasswordTarget ? this.passwordTarget.value : ''

      // Create PDFKit document options
      const docOptions = {
        size: 'A4',
        margin: 0
      }

      // Add AES-256 encryption if password is provided
      if (password) {
        // PDFKit uses AES-256 when pdfVersion is 1.7ext3
        docOptions.pdfVersion = '1.7ext3'
        docOptions.userPassword = password
        docOptions.ownerPassword = password
        docOptions.permissions = {
          printing: 'highResolution',
          modifying: true,
          copying: true,
          annotating: true,
          fillingForms: true,
          contentAccessibility: true,
          documentAssembly: true
        }
      }

      // Create PDF document
      const doc = new PDFDocument(docOptions)
      const stream = doc.pipe(blobStream())

      // Calculate dimensions to fit A4 (595.28 x 841.89 points)
      const pageWidth = 595.28
      const pageHeight = 841.89
      const imgAspectRatio = canvas.width / canvas.height
      const pageAspectRatio = pageWidth / pageHeight

      let imgWidth, imgHeight
      if (imgAspectRatio > pageAspectRatio) {
        // Image is wider than page
        imgWidth = pageWidth
        imgHeight = pageWidth / imgAspectRatio
      } else {
        // Image is taller than page
        imgHeight = pageHeight
        imgWidth = pageHeight * imgAspectRatio
      }

      // Convert canvas to data URL
      const imgData = canvas.toDataURL('image/png')

      // Add image to PDF
      doc.image(imgData, 0, 0, {
        width: imgWidth,
        height: imgHeight
      })

      // Finalize the PDF
      doc.end()

      // Handle the blob when ready
      stream.on('finish', () => {
        const blob = stream.toBlob('application/pdf')
        const filename = `${this.element.dataset.pdfFilenameValue}.pdf`

        // Create download link
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = filename
        link.click()

        // Clean up
        setTimeout(() => URL.revokeObjectURL(link.href), 100)

        resetButton()
        this.dispatch("downloaded", { detail: { filename } })
      })

    } catch (error) {
      resetButton()
      console.error("PDF generation failed:", error)
      this.dispatch("error", { detail: { error: error.message } })
    }
  }
}