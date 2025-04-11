// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { createConsumer } from "@rails/actioncable"

// Initialize Action Cable
window.App = window.App || {};
window.App.cable = createConsumer();

// To breakout of turbo frames from server e.g successful login frame we redirect to /
// https://github.com/hotwired/turbo-rails/pull/367#issuecomment-1934729149
Turbo.StreamActions.redirect = function () {
    Turbo.visit(this.target, { action: "replace" });
  };