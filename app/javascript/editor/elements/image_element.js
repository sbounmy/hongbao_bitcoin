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

  // Base64 embedded SVG for reliable PDF export (html2canvas needs embedded data)
  static placeholderSrc = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjUwIiBmaWxsPSJub25lIj4KICA8IS0tIEJhY2tncm91bmQgd2l0aCBzdWJ0bGUgYm9yZGVyIC0tPgogIDxyZWN0IHg9IjIiIHk9IjIiIHdpZHRoPSIxOTYiIGhlaWdodD0iMjQ2IiByeD0iOCIgZmlsbD0iI2Y5ZmFmYiIgc3Ryb2tlPSIjZTVlN2ViIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1kYXNoYXJyYXk9IjggNCIvPgoKICA8IS0tIFBlcnNvbiBzaWxob3VldHRlIC0tPgogIDxnIGZpbGw9IiNkMWQ1ZGIiPgogICAgPCEtLSBIZWFkIC0tPgogICAgPGNpcmNsZSBjeD0iMTAwIiBjeT0iODUiIHI9IjM1Ii8+CiAgICA8IS0tIEJvZHkvU2hvdWxkZXJzIC0tPgogICAgPHBhdGggZD0iTTEwMCAxMzAgQzUwIDEzMCAzMCAxNzAgMzAgMjAwIEwzMCAyMjAgQzMwIDIzMCAzNSAyMzUgNDUgMjM1IEwxNTUgMjM1IEMxNjUgMjM1IDE3MCAyMzAgMTcwIDIyMCBMMTcwIDIwMCBDMTcwIDE3MCAxNTAgMTMwIDEwMCAxMzBaIi8+CiAgPC9nPgoKICA8IS0tIENhbWVyYSBpY29uIC0tPgogIDxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKDc1LCAxNjApIj4KICAgIDxyZWN0IHg9IjAiIHk9IjgiIHdpZHRoPSI1MCIgaGVpZ2h0PSIzNSIgcng9IjQiIGZpbGw9IiM5Y2EzYWYiLz4KICAgIDxjaXJjbGUgY3g9IjI1IiBjeT0iMjUiIHI9IjEwIiBmaWxsPSIjNmI3MjgwIi8+CiAgICA8Y2lyY2xlIGN4PSIyNSIgY3k9IjI1IiByPSI2IiBmaWxsPSIjOWNhM2FmIi8+CiAgICA8cmVjdCB4PSI4IiB5PSIxMiIgd2lkdGg9IjEyIiBoZWlnaHQ9IjYiIHJ4PSIyIiBmaWxsPSIjNmI3MjgwIi8+CiAgPC9nPgo8L3N2Zz4K'

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
    Object.assign(this.imgEl.style, {
      width: '100%',
      height: '100%',
      objectFit: 'contain',
      display: 'block',
      pointerEvents: 'none'
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
