import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import html2canvas from "html2canvas"

export default class extends Controller {
  static targets = ["printableArea", "printButton", "pdfViewer"]

  connect() {
    console.log("PaperPDF controller connected")
  }

  async generatePDF() {
    console.log("generatePDF called")
    const printableArea = this.printableAreaTarget

    // Temporarily make printable area visible
    printableArea.classList.remove('hidden')

    // Show loading state
    this.printButtonTarget.disabled = true
    this.printButtonTarget.textContent = "Generating PDF..."

    try {
      const { default: jsPDF } = await import("jspdf")
      const pdf = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      })

      console.log("Converting to canvas...")
      const canvas = await html2canvas(printableArea, {
        scale: 2,
        useCORS: true,
        logging: true,
        backgroundColor: null
      })
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
      console.log("canvas:", canvas)
      const imgData = canvas.toDataURL('image/png')
      console.log("imgData:", imgData)
      pdf.addImage(imgData, 'PNG', 20, 70, 170, 200)

      // Create blob and display in viewer
      const pdfBlob = pdf.output('blob')
      const pdfUrl = URL.createObjectURL(pdfBlob)
      printableArea.classList.add('hidden')

      return pdfUrl
    } catch (error) {
      console.error('PDF generation failed:', error)
    } finally {
      this.printButtonTarget.disabled = false
      this.printButtonTarget.textContent = "Download Printable PDF"
    }
  }

  downloadPdf() {
    this.generatePDF().then(pdfUrl => {
      console.log("downloadPdf called")
      console.log("pdfUrl:", pdfUrl)
      window.open(pdfUrl, '_blank')
    })
  }

  showPdfViewer() {
    console.log("showPdfViewer called")
    // setTimeout(() => {
    this.generatePDF().then(pdfUrl => {
    console.log("pdfUrl:", pdfUrl)
    if (this.hasPdfViewerTarget) {
      const viewer = this.pdfViewerTarget
      viewer.setAttribute('type', 'application/pdf')
      viewer.style.width = '100%'
      viewer.style.height = '600px'
      viewer.src = pdfUrl
      viewer.classList.remove('hidden')

      viewer.onload = () => {
        console.log('PDF viewer loaded')
        console.log('Viewer dimensions:', viewer.offsetWidth, 'x', viewer.offsetHeight)
      }

      viewer.onerror = (error) => {
        console.error('Failed to load PDF:', error)
      }
    } else {
      console.error('PDF viewer target not found')
      }
      })
    // }, 3000)
  }
}
