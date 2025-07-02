import { Controller } from "@hotwired/stimulus"
import html2canvas from 'html2canvas-pro'
import { jsPDF } from 'jspdf'

export default class extends Controller {
  static targets = ["content", "viewport", "zoomDisplay", "wrapper"]
  static values = { zoom: { type: Number, default: 0.8 } }

  connect() {
    this.updateZoom()
    this.lastZoom = this.zoomValue
    this.initialPinchDistance = 0

    // Bind touch events for pinch-to-zoom
    this.boundHandleTouchStart = this.handleTouchStart.bind(this)
    this.boundHandleTouchMove = this.handleTouchMove.bind(this)
    this.boundHandleTouchEnd = this.handleTouchEnd.bind(this)
    this.boundHandleWheel = this.handleWheel.bind(this)

    this.viewportTarget.addEventListener('touchstart', this.boundHandleTouchStart, { passive: false })
    this.viewportTarget.addEventListener('touchmove', this.boundHandleTouchMove, { passive: false })
    this.viewportTarget.addEventListener('touchend', this.boundHandleTouchEnd)
    // Listen for the wheel event to handle trackpad pinch-to-zoom
    this.viewportTarget.addEventListener('wheel', this.boundHandleWheel, { passive: false })
  }

  disconnect() {
    // Clean up event listeners
    this.viewportTarget.removeEventListener('touchstart', this.boundHandleTouchStart)
    this.viewportTarget.removeEventListener('touchmove', this.boundHandleTouchMove)
    this.viewportTarget.removeEventListener('touchend', this.boundHandleTouchEnd)
    this.viewportTarget.removeEventListener('wheel', this.boundHandleWheel)
  }
  
  zoomIn() {
    this.zoomValue += 0.1
    if (this.hasZoomDisplayTarget) {
      const percentage = Math.round(this.zoomValue * 100)
      this.zoomDisplayTarget.textContent = `${percentage}%`
    }
  }

  zoomOut() {
    if (this.zoomValue > 0.2) {
      this.zoomValue -= 0.1
    }
  }

  resetZoom() {
    this.zoomValue = 0.8
  }

  zoomValueChanged() {
    this.updateZoom()
  }

  updateZoom() {
    if (this.hasContentTarget && this.hasWrapperTarget) {
      const contentWidth = this.contentTarget.offsetWidth;

      // Scale the content from its top-left corner
      this.contentTarget.style.transform = `scale(${this.zoomValue})`

      // Resize the wrapper to the new scaled dimensions
      this.wrapperTarget.style.width = `${contentWidth * this.zoomValue}px`
    }
    if (this.hasZoomDisplayTarget) {
      const percentage = Math.round(this.zoomValue * 100)
      this.zoomDisplayTarget.textContent = `${percentage}%`
    }
  }

   // Handles pinch-to-zoom on laptop trackpads.
  handleWheel(event) {
    if (event.ctrlKey) {
      event.preventDefault()
      // Adjust zoom based on the wheel's delta, but at a smaller factor
      const zoomFactor = this.zoomValue * 0.05;
      let newZoom = this.zoomValue - (event.deltaY * zoomFactor);

      // Clamp zoom to reasonable limits
      if (newZoom < 0.1) newZoom = 0.1
      if (newZoom > 4.0) newZoom = 4.0 // Max 400% zoom

      this.zoomValue = newZoom
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

      // Clamp zoom to reasonable limits
      if (newZoom < 0.1) newZoom = 0.1
      if (newZoom > 4.0) newZoom = 4.0 // Max 400% zoom

      this.zoomValue = newZoom
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
      // Convert content to canvas
      const canvas = await html2canvas(this.contentTarget, {
        scale: 2, // Higher quality
        useCORS: true, // Allow cross-origin images
        logging: true, // Enabled logging
        scrollX: -window.scrollX,
        scrollY: -window.scrollY
      })

      // Log canvas dimensions
      console.log('html2canvas generated canvas width:', canvas.width, 'height:', canvas.height);

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