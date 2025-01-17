import FormController from "controllers/form_controller"

export default class extends FormController {
  static targets = ["destination", "fee", "submitButton"]
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

  import(event) {
    console.log("import", event)
    this.bitcoinOutlet.new(null, this.bitcoinMnemonicOutlet.phrase)
  }

  transfer(event) {
    event.preventDefault()
    console.log("selectedFee", this.selectedFee.value)
    console.log("destination", this.destinationTarget.value)
    this.bitcoinOutlet.transfer(this.destinationTarget.value, this.selectedFee.value)
  }
}
