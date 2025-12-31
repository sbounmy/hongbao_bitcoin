import { BaseElement } from './base_element'

// Image element rendered as DOM
// Uses <img> tag with loading state support
export class ImageElement extends BaseElement {
  static drawer = 'photo-drawer'

  constructor(data) {
    super(data)

    this.imageUrl = null
    this.placeholderUrl = data.placeholder || null
    this.loading = false
  }

  renderContent() {
    // Container for centering
    this.container = document.createElement('div')
    this.container.className = 'editor-element-image-container'
    Object.assign(this.container.style, {
      width: '100%',
      height: '100%',
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'center'
    })

    // Image element
    this.imgEl = document.createElement('img')
    this.imgEl.className = 'editor-element-image'
    this.imgEl.draggable = false  // Prevent native browser image drag
    Object.assign(this.imgEl.style, {
      maxWidth: '100%',
      maxHeight: '100%',
      objectFit: 'contain',
      pointerEvents: 'none'  // Let parent handle all pointer events
    })
    this.imgEl.crossOrigin = 'anonymous'

    // Loading spinner
    this.spinnerEl = this.createSpinner()

    this.container.appendChild(this.imgEl)
    this.container.appendChild(this.spinnerEl)
    this.el.appendChild(this.container)

    // Load placeholder if provided
    if (this.placeholderUrl) {
      this.imgEl.src = this.placeholderUrl
    }
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
      this.imgEl.src = ''
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

  updateContent(data) {
    if (data.placeholder !== undefined && data.placeholder !== this.placeholderUrl) {
      this.placeholderUrl = data.placeholder
      if (this.placeholderUrl && !this.imageUrl) {
        this.imgEl.src = this.placeholderUrl
      }
    }
  }

  toJSON() {
    return {
      ...super.toJSON(),
      placeholder: this.placeholderUrl
    }
  }
}
