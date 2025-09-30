// Configure Turbo for ActiveAdmin
import { Turbo } from "@hotwired/turbo-rails"

// Disable Turbo because it causes issues with the drawer
if (window.location.pathname.startsWith('/admin')) {
  Turbo.session.drive = false
}