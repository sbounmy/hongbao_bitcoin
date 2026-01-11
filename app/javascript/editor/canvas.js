// Canvas - manages a container div that holds DOM elements
export class Canvas {
  constructor(containerElement, options = {}) {
    this.el = containerElement
    this.qualityScale = options.qualityScale || 3

    // Original dimensions (from background image)
    this.originalWidth = 0
    this.originalHeight = 0

    // Background
    this.backgroundUrl = null
    this.backgroundLoaded = false
    this.backgroundImgEl = null  // <img> element for background
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
    // Note: Don't set aspectRatio here - parent wrapper already has it set
    Object.assign(this.el.style, {
      position: 'relative',
      overflow: 'hidden',
      containerType: 'inline-size'  // Enable container queries for font sizing
    })
  }

  // Set background image using <img> element (not CSS background-image)
  // This ensures html2canvas captures at native resolution
  setBackgroundImage(url) {
    this.backgroundUrl = url

    // Remove existing background img if present
    if (this.backgroundImgEl) {
      this.backgroundImgEl.remove()
    }

    // Create <img> element for background
    this.backgroundImgEl = document.createElement('img')
    this.backgroundImgEl.src = url
    this.backgroundImgEl.crossOrigin = 'anonymous'
    this.backgroundImgEl.classList.add('editor-background')
    Object.assign(this.backgroundImgEl.style, {
      position: 'absolute',
      top: '0',
      left: '0',
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      zIndex: '0',
      pointerEvents: 'none'  // Allow clicks to pass through to elements
    })

    // Insert as first child so elements render on top
    this.el.insertBefore(this.backgroundImgEl, this.el.firstChild)
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
        console.error('[Canvas] image load error:', err)
        reject(err)
      }
      img.src = url
    })
  }

  // Clear all child elements (except background image)
  clear() {
    const children = Array.from(this.el.children)
    children.forEach(child => {
      // Keep background image, remove editor elements
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
