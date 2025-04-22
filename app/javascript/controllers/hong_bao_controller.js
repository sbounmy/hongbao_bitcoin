import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["paper", "paperBack", "paperFront"]
  static values = {
    currentPaper: { type: Number }
  }

  connect() {
    this.setupRefreshWarning()
  }

  setupRefreshWarning() {
    window.addEventListener('beforeunload', (e) => this.handleBeforeUnload(e))
  }

  disconnect() {
    window.removeEventListener('beforeunload', (e) => this.handleBeforeUnload(e))
  }

  handleBeforeUnload(e) {
    if (this.isTopUpStepValue) {
      e.preventDefault()
      e.returnValue = ''
      return ''
    }
  }

  currentPaperValueChanged() {
    this.paperTargets.forEach(paper => {
      paper.toggleAttribute('open', Number(paper.dataset.paperId) === this.currentPaperValue)
    })
    this.#updateURL()
  }

  paperSelected(event) {
    this.currentPaperValue = Number(event.currentTarget.dataset.paperId)
    this.dispatchPaperSelect()
  }

  get currentPaper() {
    return this.paperTargets.find(paper =>
      Number(paper.dataset.paperId) === Number(this.currentPaperValue)
    )
  }

  get currentPaperFront() {
    return this.currentPaper.dataset.frontImageValue
  }

  get currentPaperFrontElements() {
    return JSON.parse(this.currentPaper.dataset.frontElementsValue)
  }

  get currentPaperBackElements() {
    return JSON.parse(this.currentPaper.dataset.backElementsValue)
  }

  get currentPaperBack() {
    return this.currentPaper.dataset.backImageValue
  }

  get bitcoinController() {
    return this.application.getControllerForElementAndIdentifier(this.element, 'bitcoin')
  }

  dispatchPaperSelect() {
    if (this.currentPaper) {
      this.dispatch("front", { detail: { url: this.currentPaperFront, elements: this.currentPaperFrontElements } })
      this.dispatch("back", { detail: { url: this.currentPaperBack, elements: this.currentPaperBackElements } })

      this.dispatch("select", {
        detail: {
          paperId: this.currentPaper.dataset.paperId,
//          elements: JSON.parse(this.currentPaper.dataset.paperElements)
        }
      })
    }
  }

  #updateURL() {
    const url = new URL(window.location)
    if (this.currentPaperValue) {
      url.searchParams.set('paper_id', this.currentPaperValue)
    }
    window.history.pushState({}, '', url)
  }
}