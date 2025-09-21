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
  static actions = ["start"]

  connect() {
    console.log('QR Scanner Controller connected')
    const readerId = this.hasReaderIdValue ? this.readerIdValue : 'qr-reader'
    const readerElement = document.getElementById(readerId)
    
    if (!readerElement) {
      console.error(`QR reader element with id '${readerId}' not found`)
      return
    }
    
    // Store the reader element reference
    this.readerElement = readerElement
    
    // Don't initialize or start automatically unless autoStart is true
    if (this.autoStartValue) {
      this.initializeScanner()
      this.start()
    }
  }

  initializeScanner() {
    // Clean up any existing video element
    const existingVideo = this.readerElement.querySelector('video')
    if (existingVideo) {
      existingVideo.remove()
    }
    
    // Create fresh video element
    this.videoElem = document.createElement('video')
    this.videoElem.style.width = '100%'
    this.videoElem.style.height = '100%'
    this.videoElem.style.objectFit = 'cover'
    this.readerElement.appendChild(this.videoElem)

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
  }

  start() {
    console.log('Starting QR scanner')
    // Initialize scanner if not already done
    if (!this.scanner) {
      this.initializeScanner()
    }
    if (this.scanner) {
      this.scanner.start()
    }
  }

  disconnect() {
    console.log('QR Scanner Controller disconnecting')
    if (this.scanner) {
      this.scanner.stop()
      this.scanner.destroy()
      this.scanner = null
    }
    // Remove video element on disconnect
    if (this.videoElem) {
      this.videoElem.remove()
      this.videoElem = null
    }
  }
}