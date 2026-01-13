import { application } from "./application"

import EditorController from "../../../javascript/controllers/editor_controller"
import EditorTextController from "../../../javascript/controllers/editor/text_controller"

application.register("editor", EditorController)
application.register("editor--text", EditorTextController)