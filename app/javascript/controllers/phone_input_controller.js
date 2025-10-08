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
      // Use country placeholders if flags don't load
      countrySearch: false,
      i18n: {},
      loadUtils: () => import('intl-tel-input/utils'),
      // Automatically create hidden inputs for full phone number and country code
      hiddenInput: () => ({
        phone: "buyerPhoneFull",
        country: "buyerCountryCode"
      })
    })
  }

  disconnect() {
    if (this.iti) {
      this.iti.destroy()
    }
  }

  // // Get the full international number
  // getNumber() {
  //   return this.iti.getNumber()
  // }

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