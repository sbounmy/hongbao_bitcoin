import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"
import html2canvas from "html2canvas"

export default class extends Controller {
  static targets = [
    "printableArea",
    "printButton",
    "pdfViewerPlaceHolder",
    "pdfViewer",
    "frontImage",
    "backImage",
    "nextButtonWrapper"
  ]
  static values = {
    qrYoutubeUrl: String,
    frontImage: String,
    backImage: String,
    address: String,
    hongbaoQr: String
  }

  connect() {
    console.log("PaperPDF controller connected")
  }
  updateImages({ detail: { imageFrontUrl, imageBackUrl } }) {
    console.log("updateImages called", imageFrontUrl, imageBackUrl)
    this.frontImageTarget.src = imageFrontUrl
    this.backImageTarget.src = imageBackUrl
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

      // Add front and back images directly instead of using html2canvas
      if (this.frontImageTarget.src) {
        pdf.addImage(this.frontImageTarget.src, 'PNG', 20, 20, 170, 90)
      }
      if (this.backImageTarget.src) {
        pdf.addImage(this.backImageTarget.src, 'PNG', 20, 110, 170, 90)
      }

      // Left Column: What is Bitcoin (now narrower)
      pdf.setFillColor(240, 240, 240)
      pdf.rect(15, 210, 65, 8, 'F')  // Reduced width from 85 to 65
      pdf.setFont('helvetica', 'bold')
      pdf.setFontSize(14)
      pdf.setTextColor(50, 50, 50)
      pdf.text('ABOUT BITCOIN', 20, 216)

      // Left column content with QR code and text
      pdf.setFont('helvetica', 'normal')
      pdf.setFontSize(11)
      pdf.setTextColor(60, 60, 60)

      const instructions = [
        'Bitcoin is digital money that works',
        'without banks or intermediaries.',
        '',
        'Always keep your private key safe.',
        'Never share it with anyone.'
      ]

      // Add instructions text
      instructions.forEach((text, index) => {
        pdf.text(text, 20, 225 + (index * 6))
      })

      // Add QR code below the instructions (adjusted position)
      pdf.addImage(this.qrYoutubeUrlValue, 'PNG', 20, 255, 30, 30)

      // Right Column: FAQ
      pdf.setFillColor(240, 240, 240)
      pdf.rect(90, 210, 105, 8, 'F')
      pdf.setFont('helvetica', 'bold')
      pdf.setFontSize(14)
      pdf.text('HOW IT WORKS', 95, 216)

      // Add HongBao QR code in the top-right corner with new text
      pdf.addImage(this.hongbaoQrValue, 'PNG', 168, 225, 30, 30)
      pdf.setFontSize(9)
      pdf.text('Verify balance', 172, 223)

      // Right column content - FAQ text without questions
      pdf.setFont('helvetica', 'normal')
      pdf.setFontSize(12)

      const faqLines = [
        'This banknote contains keys to access',
        'your Bitcoin stored on the blockchain.',
        '',
        'Public key (IBAN) is QRcode / address.',
        'You can check balance or receive funds.',
        '',
        'Private key (Password) is used to move funds.',
        '',
        'For better security, we recommend transferring',
        'to a hardware wallet (Passport Foundation,',
        'Trezor, or Ledger).'
      ]

      // Render FAQ with reduced initial spacing
      faqLines.forEach((line, index) => {
        const y = 225 + (index * 6)  // Changed from 230 to 225 to match left column
        pdf.text(line, 95, y)
      })

      // Create blob and display in viewer
      const pdfBlob = pdf.output('blob')
      const pdfUrl = URL.createObjectURL(pdfBlob)

      return { pdfUrl, pdf }
    } catch (error) {
      console.error('PDF generation failed:', error)
    } finally {
      this.pdfViewerPlaceHolderTarget.classList.add('hidden')
      this.printButtonTarget.disabled = false
      this.printButtonTarget.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
        </svg>
        <p><strong>Generate</strong> my paper PDF</p>`
    }
  }

  get formattedDate() {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`; // YYYY-MM-DD
  }

  downloadPdf() {
    this.generatePDF().then(({ pdfUrl, pdf }) => {
      const filename = `Bitcoin_HongBao_${this.formattedDate}_${this.addressValue}.pdf`;
      pdf.save(filename);

      // Enable next button after download
      this.nextButtonWrapperTarget.dataset.downloaded = 'true';
      const nextButton = this.nextButtonWrapperTarget.querySelector('button');
      if (nextButton) {
        nextButton.disabled = false;
      }
    });
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
      viewer.style.height = '680px'
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
