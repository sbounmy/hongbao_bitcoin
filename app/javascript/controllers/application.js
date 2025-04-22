import { Application } from "@hotwired/stimulus"
import ScrollTo from '@stimulus-components/scroll-to'

const application = Application.start()


// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

application.register('scroll-to', ScrollTo)
export { application }
