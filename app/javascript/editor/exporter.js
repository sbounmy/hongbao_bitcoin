// Export functionality for editor canvases
export class Exporter {
  constructor(canvasPair, state) {
    this.canvases = canvasPair
    this.state = state
  }

  // Export both sides as separate PNG data URLs
  async exportPNG() {
    // Render clean versions (no selection handles)
    this.canvases.renderSide('front', this.state, null)
    this.canvases.renderSide('back', this.state, null)

    return {
      front: this.canvases.front.toDataURL('image/png'),
      back: this.canvases.back.toDataURL('image/png')
    }
  }

  // Export both sides combined into single image
  async exportCombined(layout = 'vertical') {
    const { front, back } = await this.exportPNG()

    // Create temporary canvas
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')

    const width = this.canvases.front.width
    const height = this.canvases.front.height

    if (layout === 'vertical') {
      canvas.width = width
      canvas.height = height * 2
    } else {
      canvas.width = width * 2
      canvas.height = height
    }

    // Load and draw images
    const frontImg = await this.loadImage(front)
    const backImg = await this.loadImage(back)

    if (layout === 'vertical') {
      ctx.drawImage(frontImg, 0, 0, width, height)
      ctx.drawImage(backImg, 0, height, width, height)
    } else {
      ctx.drawImage(frontImg, 0, 0, width, height)
      ctx.drawImage(backImg, width, 0, width, height)
    }

    return canvas.toDataURL('image/png')
  }

  // Helper to load image from data URL
  loadImage(dataUrl) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.onload = () => resolve(img)
      img.onerror = reject
      img.src = dataUrl
    })
  }

  // Download a data URL as file
  download(dataUrl, filename) {
    const a = document.createElement('a')
    a.href = dataUrl
    a.download = filename
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
  }

  // Download both sides as separate files
  async downloadBoth(baseName = 'design') {
    const { front, back } = await this.exportPNG()
    this.download(front, `${baseName}-front.png`)

    // Small delay between downloads
    await new Promise(r => setTimeout(r, 100))
    this.download(back, `${baseName}-back.png`)
  }

  // Download combined image
  async downloadCombined(filename = 'design.png', layout = 'vertical') {
    const combined = await this.exportCombined(layout)
    this.download(combined, filename)
  }
}
