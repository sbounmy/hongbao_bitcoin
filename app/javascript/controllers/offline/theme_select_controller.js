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

    const storageElement = document.querySelector("[data-controller='editor-storage']")
    if (!storageElement) return

    const field = storageElement.querySelector("input[data-editor-storage-target='field']")
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

    // Use saved customizations if available, otherwise use theme defaults
    // Elements already have 'side' property in their data
    const elements = savedCustomizations || theme.elements

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
