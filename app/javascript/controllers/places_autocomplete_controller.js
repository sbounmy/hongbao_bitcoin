import PlacesAutocomplete from 'stimulus-places-autocomplete'

export default class extends PlacesAutocomplete {
  static targets = [...PlacesAutocomplete.targets, 'countryCode', 'address2']

  connect() {
    super.connect()
  }

  countryChanged(event) {
    const newCountry = event.target.value
    this.countryValue = [newCountry]

    // Reinitialize autocomplete with new country restriction
    if (this.autocomplete) {
      // Remove old listener
      google.maps.event.clearInstanceListeners(this.autocomplete)

      // Create new autocomplete with updated country
      this.initAutocomplete()
    }

    this.clearAddressFields()
  }

  clearAddressFields() {
    if (this.hasAddressTarget && this.addressTarget.value) {
      this.addressTarget.value = ''
    }
    if (this.hasCityTarget && this.cityTarget.value) {
      this.cityTarget.value = ''
    }
    if (this.hasStateTarget && this.stateTarget.value) {
      this.stateTarget.value = ''
    }
    if (this.hasPostalCodeTarget && this.postalCodeTarget.value) {
      this.postalCodeTarget.value = ''
    }
    if (this.hasStreetNumberTarget) {
      this.streetNumberTarget.value = ''
    }
    if (this.hasRouteTarget) {
      this.routeTarget.value = ''
    }
    if (this.hasLongitudeTarget) {
      this.longitudeTarget.value = ''
    }
    if (this.hasLatitudeTarget) {
      this.latitudeTarget.value = ''
    }
    if (this.hasAddress2Target && this.address2Target.value) {
      this.address2Target.value = ''
    }
  }

  setAddressComponents(address) {
    super.setAddressComponents(address)
    if (this.hasCountryCodeTarget) {
      const countryComponent = this.place.address_components.find(component => component.types.includes('country'))
      if (countryComponent) {
        this.countryCodeTarget.value = countryComponent.short_name
      }
    }
    if (this.hasAddressTarget) {
      const streetNumber = address.street_number || ''
      const route = address.route || ''
      this.addressTarget.value = streetNumber && route ? `${streetNumber} ${route}` : (address.political || address.locality)
    }
  }
}