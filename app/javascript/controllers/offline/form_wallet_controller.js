import FormController from "./form_controller"

export default class extends FormController {
  static targets = ["destination", "fee", "submitButton", "privateKey"]
  static outlets = ["bitcoin", "bitcoin-mnemonic"]

  error(event) {
    super.error(event)
  }

  success(event) {
    super.success(event)

  }

  get selectedFee() {
    return this.feeTargets.find(target => target.checked)
  }

  import() {
    this.bitcoinOutlet.new(this.privateKeyTarget.value)
  }

  transfer(event) {
    event.preventDefault()
    console.log("selectedFee", this.selectedFee.value)
    console.log("destination", this.destinationTarget.value)
    this.bitcoinOutlet.transfer(this.destinationTarget.value, this.selectedFee.value)
  }

  successMnemonic(event) {
    this.privateKeyTarget.value = event.detail.privateKey
  }
}
