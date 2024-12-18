import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "printableArea",
    "printButton",
    "pdfViewerPlaceHolder",
    "pdfViewer",
    "frontImage",
    "backImage",
    "nextButtonWrapper",
    "mobileMessage"
  ]
  static values = {
    qrYoutubeUrl: String,
    frontImage: String,
    backImage: String,
    address: String,
    hongbaoQr: String,
    scissorsImageUrl: String
  }

  connect() {
    console.log("PaperPDF controller connected")
    this.isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent)
    if (this.isMobile && this.hasPdfViewerTarget) {
      this.pdfViewerTarget.classList.add('hidden')
    }
  }
  updateImages({ detail: { imageFrontUrl, imageBackUrl } }) {
    this.frontImageTarget.src = imageFrontUrl
    this.backImageTarget.src = imageBackUrl
  }
  async generatePDF() {
    console.log("generatePDF called")

    try {
      const { default: jsPDF } = await import("jspdf")
      const pdf = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      })

      pdf.setLineDashPattern([1, 1]);
      pdf.setDrawColor(200, 200, 200);
      pdf.setLineWidth(1);
      if (this.backImageTarget.src) {
        pdf.addImage(
          this.backImageTarget.src,
          'PNG',
          190, -80, 170, 90,
          'back',
          'FAST', // Add compression
          180 // Rotate for folding
        )
      }

      pdf.setLineDashPattern([]);

      pdf.line(20, 105, 190, 105);

      pdf.setFont('helvetica', 'normal');
      pdf.setFontSize(8);
      pdf.setTextColor(150, 150, 150);
      pdf.text('FOLD', 10, 105, { angle: 90 });

      pdf.text('FOLD', 200, 105, { angle: -90 });

      pdf.text('INSERT INTO ENVELOPE', 10, 250, { angle: 90 });

      pdf.text('INSERT INTO ENVELOPE', 200, 250, { angle: -90 });

      // Add front image below
      pdf.setLineDashPattern([1, 1]);
      pdf.addImage(this.scissorsImageUrlValue, 'PNG', 6, 1, 6, 6);
      pdf.rect(15, 5, 180, 200);
      if (this.frontImageTarget.src) {
        pdf.addImage(
          this.frontImageTarget.src,
          'PNG',
          20, 110, 170, 90,
          undefined,
          'FAST' // Add compression
        )
      }

      pdf.setFillColor(240, 240, 240)
      pdf.rect(15, 210, 65, 8, 'F')
      pdf.setFont('helvetica', 'bold')
      pdf.setFontSize(14)
      pdf.setTextColor(50, 50, 50)
      pdf.text('ABOUT BITCOIN', 20, 216)

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
      pdf.addImage(this.qrYoutubeUrlValue, 'PNG', 20, 255, 30, 30, undefined, 'FAST')

      // Right Column: FAQ
      pdf.setFillColor(240, 240, 240)
      pdf.rect(90, 210, 105, 8, 'F')
      pdf.setFont('helvetica', 'bold')
      pdf.setFontSize(14)
      pdf.text('HOW IT WORKS', 95, 216)

      // Add HongBao QR code in the top-right corner with new text
      pdf.addImage(this.hongbaoQrValue, 'PNG', 168, 225, 30, 30, undefined, 'FAST')
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
    this.generatePDF().then(({ pdfUrl, pdf }) => {
      console.log("pdfUrl:", pdfUrl)
      if (this.hasPdfViewerTarget) {
        const viewer = this.pdfViewerTarget
        viewer.setAttribute('type', 'application/pdf')
        viewer.style.width = '100%'
        viewer.style.height = '680px'

        // Only show iframe if not on mobile
        if (!this.isMobile) {
          viewer.classList.remove('hidden')
        }

        viewer.src = pdfUrl

        // Show mobile message if on mobile device
        if (this.isMobile && this.hasMobileMessageTarget) {
          this.mobileMessageTarget.classList.remove('hidden')
        }

        viewer.onload = () => {
          console.log('PDF viewer loaded')
        }

        viewer.onerror = (error) => {
          console.error('Failed to load PDF:', error)
          if (this.hasMobileMessageTarget) {
            this.mobileMessageTarget.classList.remove('hidden')
          }
        }
      }
    })
  }

  async openPdfInNewTab() {
    const { pdfUrl } = await this.generatePDF()
    window.open(pdfUrl, '_blank')
  }
}
