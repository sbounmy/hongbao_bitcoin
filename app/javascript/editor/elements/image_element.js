import { BaseElement } from './base_element'

// Image element rendered as DOM
// Uses CSS background-image with loading state support
export class ImageElement extends BaseElement {
  static drawer = 'photo-drawer'

  constructor(data) {
    super(data)

    this.imageUrl = null
    this.loading = false
  }

  renderContent() {
    // Container with background-image for displaying images
    this.container = document.createElement('div')
    this.container.className = 'editor-element-image-container'
    Object.assign(this.container.style, {
      width: '100%',
      height: '100%',
      backgroundImage: 'var(--image-placeholder)',
      backgroundSize: 'contain',
      backgroundPosition: 'center',
      backgroundRepeat: 'no-repeat'
    })

    // Loading spinner
    this.spinnerEl = this.createSpinner()

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

    // Preload image then set as background
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      this.container.style.backgroundImage = `url('${url}')`
      this.onImageLoaded?.()
    }
    img.onerror = () => {
      console.error('[ImageElement] Failed to load image:', url)
    }
    img.src = url
  }

  setLoading(loading) {
    this.loading = loading
    if (loading) {
      this.imageUrl = null
      // Restore placeholder while loading
      this.container.style.backgroundImage = 'var(--image-placeholder)'
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
