import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import html2canvas from "html2canvas"

export default class extends Controller {
  static targets = ["printableArea", "printButton", "pdfViewerPlaceHolder", "pdfViewer", "previewArea"]

  connect() {
    console.log("PaperPDF controller connected")
  }

  async generatePDF() {
    console.log("generatePDF called")
    const printableArea = this.printableAreaTarget
    const previewArea = this.previewAreaTarget
    // Temporarily make printable area visible
    printableArea.classList.remove('hidden')
    previewArea.classList.add('hidden')
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
      printableArea.classList.add('hidden')
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
      const imgData = canvas.toDataURL('image/png')
      pdf.addImage(imgData, 'PNG', 20, 70, 170, 200)

      // Create blob and display in viewer
      const pdfBlob = pdf.output('blob')
      const pdfUrl = URL.createObjectURL(pdfBlob)


      return { pdfUrl, pdf }
    } catch (error) {
      console.error('PDF generation failed:', error)
    } finally {
      this.pdfViewerPlaceHolderTarget.classList.add('hidden')
    }
  }

  downloadPdf() {
    this.generatePDF().then(({ pdfUrl, pdf }) => {
      pdf.save('Bitcoin Hong Bao.pdf')
    }).catch((error) => {
      console.error('PDF download failed:', error)
    }).finally(() => {
      this.dispatch('pdfDownloaded')
    })
  }

  showPdfViewer() {
    console.log("showPdfViewer called")
    // setTimeout(() => {
    this.generatePDF().then(({ pdfUrl, pdf }) => {
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
