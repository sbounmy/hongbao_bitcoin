import html2canvas from 'html2canvas-pro'

// DOM Exporter - captures DOM containers as images using html2canvas
// Replaces the canvas-based Exporter that uses canvas.toDataURL()
export class DOMExporter {
  constructor(canvasPair, state) {
    this.canvases = canvasPair
    this.state = state
  }

  // Export both sides as PNG data URLs
  // scale: 1 for fast preview, 3 for high-res PDF export
  async exportPNG(scale = 1) {
    const options = {
      scale,
      useCORS: true,
      allowTaint: false,
      backgroundColor: null,
      logging: false,
      // Ignore selection overlay during export
      ignoreElements: (element) => {
        return element.classList?.contains('editor-selection-overlay')
      }
    }

    const [frontCanvas, backCanvas] = await Promise.all([
      html2canvas(this.canvases.front.el, options),
      html2canvas(this.canvases.back.el, options)
    ])

    return {
      front: frontCanvas.toDataURL('image/png'),
      back: backCanvas.toDataURL('image/png')
    }
  }

  // High resolution export for PDF
  async exportHighRes() {
    return this.exportPNG(3)
  }

  // Export combined image (vertical or horizontal layout)
  async exportCombined(layout = 'vertical') {
    const { front, back } = await this.exportHighRes()

    // Load both images
    const [frontImg, backImg] = await Promise.all([
      this.loadImage(front),
      this.loadImage(back)
    ])

    // Create combined canvas
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')

    if (layout === 'vertical') {
      canvas.width = Math.max(frontImg.width, backImg.width)
      canvas.height = frontImg.height + backImg.height

      ctx.drawImage(frontImg, 0, 0)
      ctx.drawImage(backImg, 0, frontImg.height)
    } else {
      canvas.width = frontImg.width + backImg.width
      canvas.height = Math.max(frontImg.height, backImg.height)

      ctx.drawImage(frontImg, 0, 0)
      ctx.drawImage(backImg, frontImg.width, 0)
    }

    return canvas.toDataURL('image/png')
  }

  // Download both sides as separate files
  async downloadBoth(baseName = 'hongbao') {
    const { front, back } = await this.exportHighRes()

    this.download(front, `${baseName}-front.png`)
    // Small delay between downloads
    await new Promise(resolve => setTimeout(resolve, 100))
    this.download(back, `${baseName}-back.png`)
  }

  // Download combined image
  async downloadCombined(filename = 'hongbao.png', layout = 'vertical') {
    const dataUrl = await this.exportCombined(layout)
    this.download(dataUrl, filename)
  }

  // Helper to download a data URL
  download(dataUrl, filename) {
    const a = document.createElement('a')
    a.href = dataUrl
    a.download = filename
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
  }

  // Helper to load image from data URL
  loadImage(src) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.onload = () => resolve(img)
      img.onerror = reject
      img.src = src
    })
  }
}
