import PlacesAutocomplete from 'stimulus-places-autocomplete'

export default class extends PlacesAutocomplete {
  static targets = [...PlacesAutocomplete.targets, 'countryCode']
  connect() {
    super.connect()
  }

  setAddressComponents(address) {
    super.setAddressComponents(address)
    if (this.hasCountryCodeTarget) this.countryCodeTarget.value = this.place.address_components.find(component => component.types.includes('country')).short_name
    if (this.hasAddressTarget) this.addressTarget.value = `${address.street_number} ${address.route}`
  }
}