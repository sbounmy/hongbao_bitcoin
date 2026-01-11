import { BaseElement } from './base_element'

// Image element rendered as DOM
// Uses <img> element for crisp PDF export (not CSS background-image)
export class ImageElement extends BaseElement {
  static drawer = 'photo-drawer'

  constructor(data) {
    super(data)

    this.imageUrl = null
    this.loading = false
  }

  static placeholderSrc = '/images/portrait-placeholder.svg'

  renderContent() {
    // Container for image and spinner
    this.container = document.createElement('div')
    this.container.className = 'editor-element-image-container'
    Object.assign(this.container.style, {
      width: '100%',
      height: '100%',
      position: 'relative'
    })

    // <img> element for displaying images (not CSS background-image)
    // This ensures html2canvas captures at native resolution
    this.imgEl = document.createElement('img')
    this.imgEl.className = 'editor-element-image'
    this.imgEl.crossOrigin = 'anonymous'
    Object.assign(this.imgEl.style, {
      width: '100%',
      height: '100%',
      objectFit: 'contain',
      display: 'block'
    })
    // Start with placeholder
    this.imgEl.src = ImageElement.placeholderSrc

    // Loading spinner
    this.spinnerEl = this.createSpinner()

    this.container.appendChild(this.imgEl)
    this.container.appendChild(this.spinnerEl)
    this.el.appendChild(this.container)
  }

  createSpinner() {
    const spinner = document.createElement('div')
    spinner.className = 'editor-element-spinner'
    Object.assign(spinner.style, {
      position: 'absolute',
      top: '50%',
      left: '50%',
      transform: 'translate(-50%, -50%)',
      width: '24px',
      height: '24px',
      border: '3px solid #f3f3f3',
      borderTop: '3px solid #f97316',
      borderRadius: '50%',
      animation: 'spin 1s linear infinite',
      display: 'none'
    })
    return spinner
  }

  loadImage(url) {
    this.imageUrl = url
    this.loading = false
    this.hideSpinner()

    // Set image src directly (html2canvas will capture at native resolution)
    this.imgEl.onload = () => {
      this.onImageLoaded?.()
    }
    this.imgEl.onerror = () => {
      console.error('[ImageElement] Failed to load image:', url)
    }
    this.imgEl.src = url
  }

  setLoading(loading) {
    this.loading = loading
    if (loading) {
      this.imageUrl = null
      // Restore placeholder while loading
      this.imgEl.src = ImageElement.placeholderSrc
      this.showSpinner()
    } else {
      this.hideSpinner()
    }
  }

  showSpinner() {
    if (this.spinnerEl) {
      this.spinnerEl.style.display = 'block'
    }
  }

  hideSpinner() {
    if (this.spinnerEl) {
      this.spinnerEl.style.display = 'none'
    }
  }
}
