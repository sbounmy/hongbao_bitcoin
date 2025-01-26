import { Controller } from "@hotwired/stimulus"
import QrScanner from "qr-scanner"

QrScanner.WORKER_PATH = '/assets/qr-scanner-worker.min.js'

export default class extends Controller {
  static targets = ["results", "scanValue"]
  static values = {
    autoStart: Boolean
  }

  connect() {
    console.log('QR Scanner Controller connected')
    if (!this.videoElem) {
      this.videoElem = document.createElement('video')
      document.getElementById('qr-reader').appendChild(this.videoElem)
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
        highlightScanRegion: true,
        highlightCodeOutline: true,
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