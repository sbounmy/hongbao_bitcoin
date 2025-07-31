import { Controller } from "@hotwired/stimulus"
import QrScanner from "qr-scanner"

QrScanner.WORKER_PATH = '/assets/qr-scanner-worker.min.js'

export default class extends Controller {
  static targets = ["results", "scanValue"]
  static values = {
    autoStart: Boolean,
    readerId: String,
    overlayId: String
  }

  connect() {
    console.log('QR Scanner Controller connected')
    const readerId = this.hasReaderIdValue ? this.readerIdValue : 'qr-reader'
    const readerElement = document.getElementById(readerId)
    
    if (!readerElement) {
      console.error(`QR reader element with id '${readerId}' not found`)
      return
    }
    
    if (!this.videoElem) {
      this.videoElem = document.createElement('video')
      this.videoElem.style.width = '100%'
      this.videoElem.style.height = '100%'
      this.videoElem.style.objectFit = 'cover'
      readerElement.appendChild(this.videoElem)
    }

    // Get custom overlay element if provided
    let overlayElement = null
    if (this.hasOverlayIdValue) {
      overlayElement = document.getElementById(this.overlayIdValue)
    }

    this.scanner = new QrScanner(
      this.videoElem,
      result => {
        // Stop scanning immediately after detection
        this.scanner.stop()

        this.resultsTarget.textContent = 'Loading...'
        this.scanValueTarget.value = result.data
        this.element.requestSubmit()
      },
      {
        highlightScanRegion: overlayElement ? false : true,
        highlightCodeOutline: overlayElement ? false : true,
        overlay: overlayElement,
        // Only scan when QR code is clearly visible
        maxScansPerSecond: 1,
        calculateScanRegion: (video) => {
          const smallestDimension = Math.min(video.videoWidth, video.videoHeight)
          const scanRegionSize = Math.round(smallestDimension * 0.6)

          return {
            x: Math.round((video.videoWidth - scanRegionSize) / 2),
            y: Math.round((video.videoHeight - scanRegionSize) / 2),
            width: scanRegionSize,
            height: scanRegionSize,
          }
        }
      }
    )

    if (this.autoStartValue) {
      this.start()
    }
  }

  start() {
    this.scanner.start()
  }

  disconnect() {
    if (this.scanner) {
      this.scanner.stop()
      this.scanner.destroy()
    }
  }
}