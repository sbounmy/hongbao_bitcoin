import { TextElement } from "./text_element"

// Transient text element - text content is set externally and NOT persisted
// Used for elements whose content is provided at runtime (e.g., from external data sources)
// The engine doesn't know WHY text isn't persisted - that's app logic in the controller
export class TransientTextElement extends TextElement {
  constructor(data) {
    super(data)
    // Mark as sensitive by default since transient text often contains sensitive data
    this.sensitive = data.sensitive ?? true
  }

  // Override toJSON to exclude text field - text comes from external source
  toJSON() {
    const json = super.toJSON()
    delete json.text
    return json
  }
}
