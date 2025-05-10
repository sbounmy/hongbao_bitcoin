import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  MOBILE_BREAKPOINT = 768;

  connect() {
    this.handleResize = this.handleResize.bind(this);
    window.addEventListener('resize', this.handleResize);
    this.cleanupStateOnResize();
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize);
  }

  toggle() {
    if (window.innerWidth < this.MOBILE_BREAKPOINT) {
      this.element.classList.toggle('is-flipped');
    }
  }

  handleResize() {
    this.cleanupStateOnResize();
  }

  cleanupStateOnResize() {
    if (window.innerWidth >= this.MOBILE_BREAKPOINT) {
      this.element.classList.remove('is-flipped');
    }
  }
}