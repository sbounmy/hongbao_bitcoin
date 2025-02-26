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
    return this.currentPaper.querySelector('[data-controller="canva"]').dataset.canvaBackgroundImageValue
  }

  get currentPaperBack() {
    return this.currentPaper.querySelector('[data-controller="canva"]').dataset.canvaBackgroundImageValue
  }

  dispatchPaperSelect() {
    if (this.currentPaper) {
      this.dispatch("front", { detail: { url: this.currentPaperFront } })
      this.dispatch("back", { detail: { url: this.currentPaperBack } })

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

  cache({ detail: { side, base64url, paperId } }) {
    const paper = this.paperTargets.find(paper => Number(paper.dataset.paperId) === Number(paperId))
    if (paper) {
      if (side === 'back') {
        paper.dataset.paperCanvaBackUrl = base64url
      } else if (side === 'front') {
        paper.dataset.paperCanvaFrontUrl = base64url
      }
    }
    if (paper.dataset.paperCanvaFrontUrl &&
      paper.dataset.paperCanvaBackUrl &&
      Number(paperId) === this.currentPaperValue) {
      this.dispatchPaperSelect(paperId)
    }
  }
}