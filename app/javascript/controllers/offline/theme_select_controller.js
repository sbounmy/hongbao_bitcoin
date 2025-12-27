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

    // Update URL immediately for bookmarking/refresh
    this.updateUrl(theme.id)
  }

  // Update URL with theme ID
  updateUrl(themeId) {
    const url = new URL(window.location)
    url.searchParams.set('theme_id', themeId)
    window.history.replaceState({}, '', url)
  }

  // Confirm selection - URL already updated on preview
  confirm() {
    // URL is already updated in preview(), nothing else to do
  }

  // Cancel - revert to original theme and URL
  cancel() {
    if (this.originalTheme) {
      // Save current positions before reverting
      this.saveCurrentPositions()

      this.currentThemeId = this.originalIdValue
      this.applyTheme(this.originalTheme)

      // Restore original URL
      this.updateUrl(this.originalTheme.id)

      // Re-check original radio
      const originalRadio = this.radioTargets.find(r => parseInt(r.value) === this.originalIdValue)
      if (originalRadio) originalRadio.checked = true
    }
  }

  // Save current element positions for the current theme
  saveCurrentPositions() {
    if (!this.currentThemeId) return

    // Read from editor field which has the actual current positions
    const field = document.querySelector("input[data-editor-target='field']")
    if (!field?.value) return

    try {
      const allElements = JSON.parse(field.value)
      this.customizations.set(this.currentThemeId, allElements)
    } catch (e) {
      // Ignore parse errors
    }
  }

  getThemeData(radio) {
    return {
      id: radio.value,
      slug: radio.dataset.themeSlug,
      frontUrl: radio.dataset.themeFrontUrl,
      backUrl: radio.dataset.themeBackUrl,
      elements: JSON.parse(radio.dataset.themeElements || '{}')
    }
  }

  applyTheme(theme) {
    const themeId = parseInt(theme.id)
    const savedCustomizations = this.customizations.get(themeId)

    // Always start with theme defaults, then merge customizations on top
    // This ensures sensitive elements (back-side wallet elements) are never lost
    // since they are excluded from the hidden field but present in theme defaults
    let elements = { ...theme.elements }

    if (savedCustomizations) {
      // Merge customizations - only override position/size, keep all theme elements
      Object.entries(savedCustomizations).forEach(([name, customData]) => {
        if (elements[name]) {
          // Merge customization into existing theme element
          elements[name] = { ...elements[name], ...customData }
        }
      })
    }

    // Dispatch single event with all elements
    window.dispatchEvent(new CustomEvent('theme:changed', {
      detail: {
        themeId,
        frontUrl: theme.frontUrl,
        backUrl: theme.backUrl,
        elements
      }
    }))
  }
}
