import { Controller } from "@hotwired/stimulus"
import html2canvas from 'html2canvas-pro'
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

      // Use JPEG format and specify quality (0.0 to 1.0)
      // Lower quality means smaller file size but potentially worse image appearance.
      const imgData = canvas.toDataURL('image/jpeg', 0.3); // Adjust 0.7 as needed

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