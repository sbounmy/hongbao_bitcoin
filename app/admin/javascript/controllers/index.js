import { application } from "./application"

import VisualEditorController from "./visual_editor_controller"
import EditorController from "../../../javascript/controllers/editor_controller"

application.register("visual-editor", VisualEditorController)
application.register("editor", EditorController)