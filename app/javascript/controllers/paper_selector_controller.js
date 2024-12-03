import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["flipCardInner"]

  connect() {
    // Initialize any necessary state or event listeners
  }

  flipCard(event) {
    const flipCardInner = event.currentTarget.querySelector('[data-hong-bao-target="flipCardInner"]')
    flipCardInner.classList.add('rotate-y-180')
  }

  unflipCard(event) {
    const flipCardInner = event.currentTarget.querySelector('[data-hong-bao-target="flipCardInner"]')
    flipCardInner.classList.remove('rotate-y-180')
  }

  select(event) {
    const paperId = event.currentTarget.dataset.paperId
    document.getElementById('hong_bao_paper_id').value = paperId
    document.querySelector('form').requestSubmit()
  }
}