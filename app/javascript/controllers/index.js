// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import ScrollTo from '@stimulus-components/scroll-to'

eagerLoadControllersFrom("controllers", application)

application.register('scroll-to', ScrollTo)