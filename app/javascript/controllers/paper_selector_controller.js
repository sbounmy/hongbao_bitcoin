import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const paperId = event.currentTarget.dataset.paperId
    document.getElementById('hong_bao_paper_id').value = paperId
    document.querySelector('form').requestSubmit()

  }
}