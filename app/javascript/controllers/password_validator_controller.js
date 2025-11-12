import { InputValidator } from "stimulus-inline-input-validations"

export default class extends InputValidator {
  connect() {
    super.connect()
    this.fieldTargets.forEach((field) => {
      field.setAttribute('data-action', 'input->password-validator#validateInput')
    })
  }


  validateInput(event) {
    const { target: field, target: { value } } = event
    const fieldName = field.getAttribute('data-field')

    // If the field is empty and doesn't have presence validation (i.e., it's optional)
    // treat it as valid and dispatch success event
    if (value === '' && !field.hasAttribute('data-validates-presence')) {
      // Dispatch success event for empty optional fields
      this.dispatch('success', {
        detail: {
          field: fieldName,
          value: value,
          input: field,
          errors: []
        },
        bubbles: true
      })

      // Clear any existing error messages
      const errorsTargets = this.errorsTargets.filter(target =>
        target.getAttribute('data-field') === fieldName
      )
      errorsTargets.forEach(errorTarget => {
        errorTarget.innerHTML = ''
        errorTarget.style.visibility = 'hidden'
      })

      return
    }

    // If field has content, run normal validation
    super.validateInput(event)
  }
}