import { Controller } from "@hotwired/stimulus"


//   < div data-controller="toggle" data - reveal - hidden - class="d-none" >
//   <button data-action="togglel#click" type="button" class="btn">Toggle me!</button>

//   <p data-toggle-target="item1" class="d-none mt-4 hidden:[transform-xxx]">Hey 👋</p>
//   <p data-toggle-target="item2" class="d-none mt-4">You can have multiple items</p>
// </div>

export default class extends Controller {

  static targets = ["item_1", "item_2"]

  click() {
    if (item1Target == 'show') {
      item1Target.hide()
      item2Target.show()
    } else {
      item2Target.hide()
      item1Target.show()
    }
  }
}


// app / views / index.html
//   < div data - controller="reveal" data - reveal - hidden - class="d-none" >
//   <button data-action="reveal#toggle" type="button" class="btn">Toggle me!</button>

//   <p data-reveal-target="item" class="d-none mt-4">Hey 👋</p>
//   <p class="d-none mt-4 hidden:(data-reveal-target="item":show) ">You can have multiple items</p>
// </div >