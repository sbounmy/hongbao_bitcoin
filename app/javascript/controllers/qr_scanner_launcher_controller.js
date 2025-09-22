import { Controller } from "@hotwired/stimulus"

// Simple controller to launch QR scanner when reveal happens
export default class extends Controller {
  static targets = ["scanner"]
  
  launch() {
    console.log('Launching QR scanner')
    // Wait a bit for the reveal animation to complete and DOM to update
    setTimeout(() => {
      // Find the qr-scanner controller in the revealed element
      const scannerElement = this.scannerTarget.querySelector('[data-controller*="qr-scanner"]')
      if (scannerElement) {
        const scannerController = this.application.getControllerForElementAndIdentifier(scannerElement, 'qr-scanner')
        if (scannerController && scannerController.start) {
          console.log('Starting QR scanner')
          scannerController.start()
        }
      }
    }, 100)
  }
}