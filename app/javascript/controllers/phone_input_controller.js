import { Controller } from "@hotwired/stimulus"
import intlTelInput from 'intl-tel-input'

export default class extends Controller {
  static targets = ["input", "countryCode"]
  static values = {
    defaultCountry: String,
    preferredCountries: Array
  }

  connect() {
    // Initialize intl-tel-input
    this.iti = intlTelInput(this.inputTarget, {
      // Show only these countries at the top
      preferredCountries: this.hasPreferredCountriesValue
        ? this.preferredCountriesValue
        : ["fr", "us", "gb", "de", "ca", "au"],
      // Initial country
      initialCountry: this.hasDefaultCountryValue
        ? this.defaultCountryValue
        : "fr",
      // Separate dial code from the input
      separateDialCode: true,
      // Format as you type
      formatOnDisplay: true,
      // National mode (without country code in the input)
      nationalMode: false,
      // Allow dropdown
      allowDropdown: true,
      // Auto placeholder
      autoPlaceholder: "aggressive",
      // Container for dropdown to handle z-index issues
      dropdownContainer: document.body,
      // Use CDN for utils and load flags with CSS
      utilsScript: "https://cdn.jsdelivr.net/npm/intl-tel-input@25.11.2/build/js/utils.js",
      // Use country placeholders if flags don't load
      countrySearch: false,
      i18n: {},
      // Load flags with CSS from CDN
      loadUtilsOnInit: "https://cdn.jsdelivr.net/npm/intl-tel-input@25.11.2/build/js/utils.js"
    })

    // Listen for country changes in the phone input
    this.inputTarget.addEventListener("countrychange", () => {
      this.handleCountryChange()
    })

    // Store initial country code
    this.handleCountryChange()
  }

  disconnect() {
    if (this.iti) {
      this.iti.destroy()
    }
  }

  handleCountryChange() {
    const countryData = this.iti.getSelectedCountryData()

    // Update hidden country code field if it exists
    if (this.hasCountryCodeTarget) {
      this.countryCodeTarget.value = countryData.iso2.toUpperCase()
    }
  }

  // Get the full international number
  getNumber() {
    return this.iti.getNumber()
  }

  // Check if number is valid
  isValid() {
    return this.iti.isValidNumber()
  }
}