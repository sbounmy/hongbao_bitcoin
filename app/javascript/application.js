// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { createConsumer } from "@rails/actioncable"
import { Application } from "@hotwired/stimulus"
import ScrollTo from '@stimulus-components/scroll-to'
// Import Flowbite's Turbo build - it should handle initialization
import "flowbite"

// Initialize Action Cable
window.App = window.App || {};
window.App.cable = createConsumer();

// To breakout of turbo frames from server e.g successful login frame we redirect to /
// https://github.com/hotwired/turbo-rails/pull/367#issuecomment-1934729149
Turbo.StreamActions.redirect = function () {
    Turbo.visit(this.target, { action: "replace" });
  };

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

application.register('scroll-to', ScrollTo)

// Remove or comment out the manual initFlowbite calls,
// as the Turbo build should handle this automatically.
/*
document.addEventListener('turbo:load', () => {
  initFlowbite();
})
document.addEventListener('turbo:render', () => {
  initFlowbite();
})
document.addEventListener('turbo:frame-render', () => {
  initFlowbite();
})
// Optional: Re-initialize after Stimulus controllers connect if needed
// document.addEventListener('stimulus-connect', () => {
//   initFlowbite();
// })

// Initial load just in case
initFlowbite();
*/

export { application }