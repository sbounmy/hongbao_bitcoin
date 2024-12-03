import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["flipCardInner"]
  static values = {
    selectedPaperId: String
  }

  connect() {
    // Check for paper_id in URL params
    const url = new URL(window.location)
    const paperIdFromUrl = url.searchParams.get('paper_id')

    if (paperIdFromUrl) {
      this.selectedPaperIdValue = paperIdFromUrl
      this.updateSelectedState()
    }

    this.updateNextButton()
  }

  select(event) {
    const paperId = event.currentTarget.dataset.paperId
    this.selectedPaperIdValue = paperId

    // Update hidden input
    // document.querySelector('input[name="hong_bao[paper_id]"]').value = paperId

    // Update URL
    const url = new URL(window.location)
    url.searchParams.set('paper_id', paperId)
    window.history.pushState({}, '', url)

    this.updateSelectedState()
    this.updateNextButton()
  }

  // Private methods
  updateSelectedState() {
    // Update all cards: remove selection styling and add opacity
    this.element.querySelectorAll('[data-paper-id]').forEach(card => {
      card.classList.remove('ring-8', 'ring-[#FFB636]')
      card.classList.add('opacity-50') // Add opacity to all cards
    })

    // Add selected state to chosen card and remove opacity
    const selectedCard = this.element.querySelector(`[data-paper-id="${this.selectedPaperIdValue}"]`)
    if (selectedCard) {
      selectedCard.classList.add('ring-8', 'ring-[#FFB636]')
      selectedCard.classList.remove('opacity-50') // Remove opacity from selected card
    }
  }

  updateNextButton() {
    const nextButton = document.querySelector('[data-hong-bao-target="nextButton"]')
    if (nextButton) {
      nextButton.disabled = !this.selectedPaperIdValue
      nextButton.classList.toggle('opacity-50', !this.selectedPaperIdValue)
      nextButton.classList.toggle('cursor-not-allowed', !this.selectedPaperIdValue)
    }
  }
}