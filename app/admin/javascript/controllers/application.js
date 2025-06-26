import { Application } from "@hotwired/stimulus"
import interact from "interactjs"
const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application
window.Interact = interact
export { application }