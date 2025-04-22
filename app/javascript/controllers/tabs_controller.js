import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = ['active']
  static targets = ["btn", "tab"]
  static values = { defaultTab: String }

  connect() {
    if(!this.hasBtnTargets) {
      return
    }
    // Hide all tabs initially
    this.tabTargets.forEach(tab => tab.classList.add('hidden'))

    // Show default tab
    const selectedTab = this.tabTargets.find(element =>
      element.dataset.tabId === this.defaultTabValue
    )
    selectedTab.classList.remove('hidden')

    // Activate default button
    const selectedBtn = this.btnTargets.find(element =>
      element.dataset.tabId === this.defaultTabValue
    )
    selectedBtn.classList.add(...this.activeClasses)
  }

  select(event) {
    const selectedTabId = event.currentTarget.dataset.tabId
    const selectedTab = this.tabTargets.find(element =>
      element.dataset.tabId === selectedTabId
    )

    if (selectedTab.classList.contains('hidden')) {
      // Hide all tabs and deactivate all buttons
      this.tabTargets.forEach(tab => tab.classList.add('hidden'))
      this.btnTargets.forEach(btn =>
        btn.classList.remove(...this.activeClasses)
      )

      // Show selected tab and activate button
      selectedTab.classList.remove('hidden')
      event.currentTarget.classList.add(...this.activeClasses)
    }
  }
}
