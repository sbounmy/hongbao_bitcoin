import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio"]
  static values = { originalId: Number }

  connect() {
    // Store customizations per theme (keyed by theme ID)
    this.customizations = new Map()

    // Track current theme ID
    this.currentThemeId = this.originalIdValue

    // Store original theme data for cancel
    const originalRadio = this.radioTargets.find(r => parseInt(r.value) === this.originalIdValue)
    if (originalRadio) {
      this.originalTheme = this.getThemeData(originalRadio)
    }
  }

  // Preview theme immediately when radio changes
  preview(event) {
    // Save current positions before switching
    this.saveCurrentPositions()

    const theme = this.getThemeData(event.target)
    this.currentThemeId = parseInt(theme.id)
    this.applyTheme(theme)
  }

  // Confirm selection - update URL and close
  confirm() {
    const selectedRadio = this.radioTargets.find(r => r.checked)
    if (selectedRadio) {
      const theme = this.getThemeData(selectedRadio)
      // Update URL for bookmarking/refresh
      const url = new URL(window.location)
      url.searchParams.set('theme_id', theme.slug)
      window.history.replaceState({}, '', url)
    }
  }

  // Cancel - revert to original theme
  cancel() {
    if (this.originalTheme) {
      // Save current positions before reverting
      this.saveCurrentPositions()

      this.currentThemeId = this.originalIdValue
      this.applyTheme(this.originalTheme)

      // Re-check original radio
      const originalRadio = this.radioTargets.find(r => parseInt(r.value) === this.originalIdValue)
      if (originalRadio) originalRadio.checked = true
    }
  }

  // Save current element positions for the current theme
  saveCurrentPositions() {
    if (!this.currentThemeId) return

    const frontPositions = this.getCurrentPositions('front')
    const backPositions = this.getCurrentPositions('back')

    if (Object.keys(frontPositions).length > 0 || Object.keys(backPositions).length > 0) {
      this.customizations.set(this.currentThemeId, {
        front: frontPositions,
        back: backPositions
      })
    }
  }

  // Get current positions from the hidden elements field
  getCurrentPositions(side) {
    const field = document.querySelector(`input[name="${side}_elements"]`)
    if (field && field.value) {
      try {
        return JSON.parse(field.value)
      } catch (e) {
        return {}
      }
    }
    return {}
  }

  getThemeData(radio) {
    return {
      id: radio.value,
      slug: radio.dataset.themeSlug,
      frontUrl: radio.dataset.themeFrontUrl,
      backUrl: radio.dataset.themeBackUrl,
      elements: JSON.parse(radio.dataset.themeElements)
    }
  }

  applyTheme(theme) {
    const themeId = parseInt(theme.id)
    const savedCustomizations = this.customizations.get(themeId)

    this.dispatchThemeChange('front', theme, savedCustomizations?.front)
    this.dispatchThemeChange('back', theme, savedCustomizations?.back)
  }

  dispatchThemeChange(side, theme, savedPositions) {
    // Element names in snake_case (as stored in theme.elements)
    const frontElements = ['portrait', 'public_address_qrcode', 'public_address_text']
    const backElements = ['private_key_qrcode', 'private_key_text', 'mnemonic_text']

    const elementNames = side === 'front' ? frontElements : backElements
    const elements = {}

    elementNames.forEach(name => {
      // savedPositions uses camelCase keys (from editor controller)
      const camelName = this.camelize(name)

      // Use saved positions if available, otherwise use theme defaults
      if (savedPositions && savedPositions[camelName]) {
        elements[camelName] = savedPositions[camelName]
      } else if (theme.elements[name]) {
        // Convert theme defaults to camelCase key format
        elements[camelName] = theme.elements[name]
      }
    })

    window.dispatchEvent(new CustomEvent(`theme:${side}Changed`, {
      detail: {
        url: side === 'front' ? theme.frontUrl : theme.backUrl,
        elements
      }
    }))
  }

  // Convert snake_case to camelCase
  camelize(name) {
    return name
      .split('_')
      .map((word, index) =>
        index === 0 ? word.toLowerCase() : word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
      )
      .join('')
  }
}
