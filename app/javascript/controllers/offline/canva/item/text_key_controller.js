import TextController from "./text_controller"

// Base class for key text items (mnemonic, private_key, public_address)
// Text comes from wallet JSON, not persisted to elements JSON
export default class TextKeyController extends TextController {
  static drawer = "keys-drawer"

  // Don't persist text (comes from wallet)
  toJSON() {
    const json = super.toJSON()
    delete json.text
    return json
  }
}
