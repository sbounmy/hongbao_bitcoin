import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import html2canvas from "html2canvas"

export default class extends Controller {
  static targets = ["printableArea", "printButton"]

  connect() {
    console.log("PaperPDF controller connected")
  }

  async generatePDF() {
    console.log("generatePDF called")
    const printableArea = this.printableAreaTarget
    console.log("printableArea:", printableArea)

    // Temporarily make printable area visible
    printableArea.classList.remove('hidden')

    // Show loading state
    this.printButtonTarget.disabled = true
    this.printButtonTarget.textContent = "Generating PDF..."

    try {
      // Dynamically import jsPDF
      const { default: jsPDF } = await import("jspdf")

      // Create PDF
      const pdf = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      })

      console.log("Converting to canvas...")
      // Convert the HTML content to canvas
      const canvas = await html2canvas(printableArea, {
        scale: 2, // Higher quality
        useCORS: true,
        logging: true, // Enable logging
        backgroundColor: null
      })
      console.log("Canvas created:", canvas)

      // Add cutting instructions
      pdf.setFontSize(14)
      pdf.text('Cutting Instructions:', 20, 20)
      pdf.setFontSize(12)
      pdf.text([
        '1. Cut along the dashed lines',
        '2. Fold the instruction slip along the marked lines',
        '3. Place the folded slip inside the red envelope',
        '4. Keep the recovery information in a safe place'
      ], 20, 30)

      // Add the hong bao content
      const imgData = canvas.toDataURL('image/png')
      pdf.addImage(imgData, 'PNG', 20, 70, 170, 200)

      // Save the PDF
      pdf.save('bitcoin-hongbao.pdf')
    } catch (error) {
      console.error('PDF generation failed:', error)
    } finally {
      // Reset button state and hide printable area
      this.printButtonTarget.disabled = false
      this.printButtonTarget.textContent = "Download Printable PDF"
      printableArea.classList.add('hidden')
    }
  }
}