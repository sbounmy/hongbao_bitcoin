import { Controller } from "@hotwired/stimulus"

// A generic controller to hide one element and show another,
// making it perfect for "switcher" UIs.
//
// To use, add the controller to a parent element.
// On a button, specify which element to show and which to hide.
//
// Example:
// <div data-controller="toggle">
//   <button data-action="toggle#switch"
//           data-toggle-show-param="#preview"
//           data-toggle-hide-param="#form">
//     Show Preview
//   </button>
//
//   <div id="form">...</div>
//   <div id="preview" class="hidden">...</div>
// </div>
export default class extends Controller {
  static values = {
    // Defines the CSS class to use for hiding elements.
    // Defaults to "hidden" but can be customized.
    // Example: data-toggle-hidden-class-value="d-none"
    hiddenClass: { type: String, default: 'hidden' }
  }

  // Action to switch visibility between two elements.
  switch(event) {
    // Get the `show` and `hide` CSS selectors from the
    // data-toggle-show-param and data-toggle-hide-param attributes.
    const { show, hide } = event.params

    console.log('toggling....')
    if (hide) {
      // Find the element to hide and add the hidden class.
      const el = document.querySelector(hide)
      if (el) el.classList.add(this.hiddenClassValue)
    }

    if (show) {
      // Find the element to show and remove the hidden class.
      const el = document.querySelector(show)
      if (el) el.classList.remove(this.hiddenClassValue)
    }
  }
}