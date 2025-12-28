// DOM Canvas - manages a container div that holds DOM elements
// Replaces the Canvas class that uses <canvas> 2D context
export class DOMCanvas {
  constructor(containerElement, options = {}) {
    this.el = containerElement
    this.qualityScale = options.qualityScale || 3

    // Original dimensions (from background image)
    this.originalWidth = 0
    this.originalHeight = 0

    // Background
    this.backgroundUrl = null
    this.backgroundLoaded = false
  }

  get width() {
    return this.originalWidth
  }

  get height() {
    return this.originalHeight
  }

  // Initialize container with dimensions
  init(width, height) {
    this.originalWidth = width
    this.originalHeight = height

    // Set container style for positioning context
    Object.assign(this.el.style, {
      position: 'relative',
      overflow: 'hidden',
      containerType: 'inline-size'  // Enable container queries for font sizing
    })
  }

  // Set background image via CSS
  setBackgroundImage(url) {
    this.backgroundUrl = url
    Object.assign(this.el.style, {
      backgroundImage: `url(${url})`,
      backgroundSize: 'cover',
      backgroundPosition: 'center'
    })
  }

  // Load background image and get dimensions
  loadBackgroundImage(url) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.crossOrigin = 'anonymous'
      img.onload = () => {
        this.init(img.width, img.height)
        this.setBackgroundImage(url)
        this.backgroundLoaded = true
        resolve(img)
      }
      img.onerror = (err) => {
        console.error('[DOMCanvas] image load error:', err)
        reject(err)
      }
      img.src = url
    })
  }

  // Clear all child elements (except labels)
  clear() {
    const children = Array.from(this.el.children)
    children.forEach(child => {
      // Keep labels and non-element children
      if (child.classList.contains('editor-element')) {
        child.remove()
      }
    })
  }

  // Convert client coordinates to percentage (0-100)
  clientToPercentage(clientX, clientY) {
    const rect = this.el.getBoundingClientRect()
    return {
      x: ((clientX - rect.left) / rect.width) * 100,
      y: ((clientY - rect.top) / rect.height) * 100
    }
  }

  // Convert percentage to client coordinates
  percentageToClient(percentX, percentY) {
    const rect = this.el.getBoundingClientRect()
    return {
      x: rect.left + (percentX / 100) * rect.width,
      y: rect.top + (percentY / 100) * rect.height
    }
  }

  // Get container bounds
  getBoundingRect() {
    return this.el.getBoundingClientRect()
  }

  // Add element to container
  appendChild(element) {
    this.el.appendChild(element)
  }

  // Remove element from container
  removeChild(element) {
    if (this.el.contains(element)) {
      this.el.removeChild(element)
    }
  }
}
