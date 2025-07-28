import { Controller } from "@hotwired/stimulus"
import html2canvas from 'html2canvas-pro'
import { jsPDF } from 'jspdf'

export default class extends Controller {
  static targets = ["content", "viewport", "zoomDisplay", "wrapper"]
  static values = { 
    zoom: { type: Number, default: 0.8 },
    minZoom: { type: Number, default: 0.4 },
    maxZoom: { type: Number, default: 5.0 },
    zoomStep: { type: Number, default: 0.1 },
    wheelZoomSpeed: { type: Number, default: 0.005 }
  }

  connect() {
    this.lastZoom = this.zoomValue
    this.pendingCursorPosition = null
    this.initialPinchDistance = 0
    // Initial zoom setup
    this.applyZoomTransform()
    this.updateZoomDisplay()
  }

  disconnect() {
    this.pendingCursorPosition = null
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
    if (this.hasZoomDisplayTarget) {
      const percentage = Math.round(this.zoomValue * 100)
      this.zoomDisplayTarget.textContent = `${percentage}%`
    }
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

  async download(event) {
    event.preventDefault()

    try {
      this.contentTarget.style.transform = '' // Remove zoom transform
      this.viewportTarget.scrollTop = 0       // Scroll to top
      this.viewportTarget.scrollLeft = 0      // Scroll to left
      // Convert content to canvas
      const canvas = await html2canvas(this.contentTarget, {
        scale: 2, // Higher quality
        useCORS: true, // Allow cross-origin images
        logging: false,
        scrollX: -window.scrollX, // negate scroll position to prevent clipping upon pdf download
        scrollY: -window.scrollY
      })

      // Create PDF with A4 dimensions
      const pdf = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      })

      // Calculate dimensions to fit A4
      const imgWidth = 210 // A4 width in mm
      const imgHeight = (canvas.height * imgWidth) / canvas.width

      // Use JPEG format and specify quality (0.0 to 1.0)
      // Lower quality means smaller file size but potentially worse image appearance.
      const imgData = canvas.toDataURL('image/jpeg', 0.7); // Adjust 0.7 as needed

      // Add the image to PDF
      pdf.addImage(
        imgData,
        'JPEG',
        0,
        0,
        imgWidth,
        imgHeight,
        undefined,
        'FAST'
      )

      const filename = `${this.element.dataset.pdfFilenameValue}.pdf`;

      // Save the PDF
      pdf.save(filename)

      // Dispatch event on successful download
      this.dispatch("downloaded", { detail: { filename } })

    } catch (error) {
      console.error("PDF generation failed:", error)
      this.dispatch("error", { detail: { error: error.message } })
    }
  }
}