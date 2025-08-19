import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("ThemeController connected")
    
    // Check for saved theme preference or use system preference
    const savedTheme = localStorage.getItem("theme") || this.getSystemTheme()
    console.log("Initial theme:", savedTheme)
    this.setTheme(savedTheme)
    
    // Set initial checkbox state
    const checkbox = this.element.querySelector('input[type="checkbox"]')
    if (checkbox) {
      checkbox.checked = savedTheme === "dark"
    }
    
    // Listen for theme changes in other tabs
    window.addEventListener("storage", (e) => {
      if (e.key === "theme") {
        this.setTheme(e.newValue)
      }
    })
    
    // Listen for system theme changes
    const darkModeMediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    darkModeMediaQuery.addEventListener("change", (e) => {
      // Only update if user hasn't manually set a preference
      if (!localStorage.getItem("theme")) {
        this.setTheme(e.matches ? "dark" : "light")
      }
    })
  }
  
  getSystemTheme() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }
  
  toggle(event) {
    // Get the new theme based on checkbox state
    const newTheme = event.target.checked ? "dark" : "light"
    this.setTheme(newTheme)
  }
  
  setTheme(theme) {
    console.log("Setting theme to:", theme)
    
    // Update data-theme attribute
    document.documentElement.setAttribute("data-theme", theme)
    
    // Save to localStorage
    localStorage.setItem("theme", theme)
    
    // Update checkbox state if needed (when called from outside toggle)
    const checkbox = this.element.querySelector('input[type="checkbox"]')
    if (checkbox && checkbox.checked !== (theme === "dark")) {
      checkbox.checked = theme === "dark"
    }
    
    // Dispatch custom event for other components
    window.dispatchEvent(new CustomEvent("theme-changed", { detail: { theme } }))
  }
}