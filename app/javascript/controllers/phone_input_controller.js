import { Controller } from "@hotwired/stimulus"
import intlTelInput from 'intl-tel-input'

export default class extends Controller {
  static targets = ["input"]
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

    // Update the input value to always contain the full international number before form submission
    const form = this.inputTarget.closest('form')
    if (form) {
      form.addEventListener('submit', (e) => {
        // Get the full international number and update the input value
        const fullNumber = this.iti.getNumber()
        if (fullNumber) {
          this.inputTarget.value = fullNumber
        }
      })
    }
  }

  disconnect() {
    if (this.iti) {
      this.iti.destroy()
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

  // Set a phone number and auto-detect country
  setNumber(number) {
    if (number && this.iti) {
      this.inputTarget.value = number
      this.iti.setNumber(number)
    }
  }

  // Handle country change from the country select dropdown
  countryChanged(event) {
    const newCountry = event.target.value.toLowerCase()

    // Update the default country for intl-tel-input
    if (this.iti) {
      // Only update the country if phone field is empty
      if (!this.inputTarget.value || this.inputTarget.value.trim() === '') {
        this.iti.setCountry(newCountry)
      }
      // If there's a value, user can keep their different country code
      // but the dropdown will show the new country as an option
    }
  }
}