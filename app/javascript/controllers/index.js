// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import Clipboard from '@stimulus-components/clipboard'
import Dialog from '@stimulus-components/dialog'
import Dropdown from '@stimulus-components/dropdown'
import Reveal from '@stimulus-components/reveal'
import ScrollTo from '@stimulus-components/scroll-to'
import TextareaAutogrow from 'stimulus-textarea-autogrow'
import { createConsumer } from "@rails/actioncable"
eagerLoadControllersFrom("controllers", application)

// To breakout of turbo frames from server e.g successful login frame we redirect to /
// https://github.com/hotwired/turbo-rails/pull/367#issuecomment-1934729149
Turbo.StreamActions.redirect = function () {
    Turbo.visit(this.target, { action: "replace" });
};


// Initialize Action Cable
window.App = window.App || {};
window.App.cable = createConsumer();

application.register('clipboard', Clipboard)
application.register('dialog', Dialog)
application.register('dropdown', Dropdown)
application.register('reveal', Reveal)
application.register('scroll-to', ScrollTo)
application.register('textarea-autogrow', TextareaAutogrow)