import { TextElement } from "../text_element"

// Base for wallet text elements (private key, public address, mnemonic)
// Text content is set externally and NOT persisted (sensitive wallet data)
export class WalletTextElement extends TextElement {
  static sensitive = true

  constructor(data) {
    super(data)
    this.sensitive = true
  }

  // Override toJSON to exclude text - comes from external wallet data
  toJSON() {
    const json = super.toJSON()
    delete json.text
    return json
  }
}
