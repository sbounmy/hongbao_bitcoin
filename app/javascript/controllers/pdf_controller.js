import { Controller } from "@hotwired/stimulus"
import html2canvas from 'html2canvas'
import { jsPDF } from 'jspdf'

export default class extends Controller {
  static targets = ["content"]

  async download(event) {
    event.preventDefault()

    try {
      // Convert content to canvas
      const canvas = await html2canvas(this.contentTarget, {
        scale: 2, // Higher quality
        useCORS: true, // Allow cross-origin images
        logging: false
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

      // Add the image to PDF
      pdf.addImage(
        canvas.toDataURL('image/png'),
        'PNG',
        0,
        0,
        imgWidth,
        imgHeight,
        undefined,
        'FAST'
      )

      // Generate filename using timestamp
      const filename = `document_${new Date().toISOString().slice(0,10)}.pdf`

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