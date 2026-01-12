import { BaseElement } from './base_element'

// QR code element rendered as DOM
// Uses <img> tag for QR code images
export class QRElement extends BaseElement {
  constructor(data) {
    super(data)

    this.imageUrl = data.image_url || data.imageUrl || null
    this.color = data.color || null
  }

  renderContent() {
    // Container for bottom-aligned square QR
    this.container = document.createElement('div')
    this.container.className = 'editor-element-qr-container'
    Object.assign(this.container.style, {
      width: '100%',
      height: '100%',
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'flex-start'
    })

    // QR image element (always square)
    this.imgEl = document.createElement('img')
    this.imgEl.className = 'editor-element-qr select-none'
    this.imgEl.draggable = false  // Prevent native browser image drag
    Object.assign(this.imgEl.style, {
      width: '100%',
      aspectRatio: '1',
      objectFit: 'contain',
      pointerEvents: 'none'  // Let parent handle all pointer events
    })

    this.container.appendChild(this.imgEl)
    this.el.appendChild(this.container)

    // Load image if URL provided
    if (this.imageUrl) {
      this.imgEl.src = this.imageUrl
    }
  }

  // Load image from URL
  loadImage(url) {
    this.imageUrl = url
    this.imgEl.onload = () => {
      this.onImageLoaded?.()
    }
    this.imgEl.onerror = () => {
      console.error('[QRElement] Failed to load image:', url)
    }
    this.imgEl.src = url
  }

  // Set image directly from base64 data
  setImageData(base64Data) {
    if (!base64Data) {
      this.imgEl.src = ''
      return
    }
    this.imgEl.src = base64Data
  }

  updateContent(data) {
    const newUrl = data.image_url || data.imageUrl
    if (newUrl !== undefined && newUrl !== this.imageUrl) {
      this.imageUrl = newUrl
      if (this.imageUrl) {
        this.loadImage(this.imageUrl)
      } else {
        this.imgEl.src = ''
      }
    }

    if (data.color !== undefined) this.color = data.color
  }

  toJSON() {
    return {
      ...super.toJSON(),
      color: this.color
      // image_url is not persisted - comes from external wallet data
    }
  }
}

// Wallet QR elements with dataKey for external data binding
export class PrivateKeyQRElement extends QRElement {
  static drawer = 'keys-drawer'
  static dataKey = 'private_key_qrcode'
}

export class PublicAddressQRElement extends QRElement {
  static drawer = 'keys-drawer'
  static dataKey = 'public_address_qrcode'
}
