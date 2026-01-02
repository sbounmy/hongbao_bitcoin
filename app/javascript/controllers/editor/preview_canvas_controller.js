import { Controller } from "@hotwired/stimulus"

// Displays cloned DOM elements from the editor in the PDF preview
// Listens via data-action: editor:exported@window->editor--preview-canvas#handleExported
export default class extends Controller {
  static targets = ["front", "back", "layoutContainer", "frontWrapper", "backWrapper", "foldLine"]

  handleExported(event) {
    const { frontEl, backEl, frameData } = event.detail

    // Apply frame data first (dimensions, rotation, fold line, layout)
    if (frameData) {
      this.applyFrameData(frameData)
    }

    // Replace front/back content with clones from editor
    if (frontEl && this.hasFrontTarget) {
      this.styleCloneForPreview(frontEl)
      this.frontTarget.replaceWith(frontEl)
      frontEl.setAttribute('data-editor--preview-canvas-target', 'front')
    }

    if (backEl && this.hasBackTarget) {
      this.styleCloneForPreview(backEl)
      this.backTarget.replaceWith(backEl)
      backEl.setAttribute('data-editor--preview-canvas-target', 'back')
    }
  }

  // Apply all frame-dependent classes from frameData (no hardcoded values!)
  applyFrameData(frameData) {
    const { cssClasses, rotationBack, foldLine, layoutDirection, layoutClasses } = frameData

    // Update wrapper dimensions (e.g., "w-[63mm] h-[88mm]" or "w-[150mm] h-[75mm]")
    ;[this.frontWrapperTarget, this.backWrapperTarget].forEach(wrapper => {
      if (!wrapper) return
      // Remove old dimension classes using regex
      wrapper.className = wrapper.className.replace(/w-\[\d+mm\]\s*/g, '').replace(/h-\[\d+mm\]\s*/g, '')
      // Add new dimension classes
      if (cssClasses) {
        cssClasses.split(' ').forEach(cls => wrapper.classList.add(cls))
      }
    })

    // Update back wrapper rotation (landscape uses "transform rotate-180")
    if (this.hasBackWrapperTarget) {
      this.backWrapperTarget.classList.remove('transform', 'rotate-180')
      if (rotationBack) {
        rotationBack.split(' ').forEach(cls => this.backWrapperTarget.classList.add(cls))
      }
    }

    // Update fold line direction (portrait: "border-l-2", landscape: "border-t-2")
    if (this.hasFoldLineTarget) {
      this.foldLineTarget.classList.remove('border-t-2', 'border-l-2')
      if (foldLine) {
        this.foldLineTarget.classList.add(foldLine)
      }
    }

    // Update cuttable content layout (direction + layout classes)
    if (this.hasLayoutContainerTarget) {
      const cuttableDiv = this.layoutContainerTarget.firstElementChild
      if (cuttableDiv) {
        // Remove old layout classes
        cuttableDiv.classList.remove('flex-row', 'flex-col', 'overflow-x-auto', 'overflow-y-auto')
        cuttableDiv.classList.remove('items-stretch', 'min-h-[88mm]', 'w-[150mm]')
        // Add new layout direction
        if (layoutDirection) {
          layoutDirection.split(' ').forEach(cls => cuttableDiv.classList.add(cls))
        }
        // Add new layout classes
        if (layoutClasses) {
          layoutClasses.split(' ').forEach(cls => cuttableDiv.classList.add(cls))
        }
      }
    }
  }

  // Ensure cloned element fills its container properly
  styleCloneForPreview(el) {
    Object.assign(el.style, {
      width: '100%',
      height: '100%',
      position: 'relative'
    })
  }
}
