import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "canvas", "element", "frontImage", "backImage", "frontTab", "backTab",
    "propertiesPanel", "panelTitle", "panelColorInput",
    "panelColorContainer", "panelSizeContainer", "panelMaxWidthContainer", "panelSizeLabel",
    "panelHandle", "panelPreviewTextContainer", "panelPreviewTextInput",
    "panelXInput", "panelYInput", "panelSizeInput", "panelMaxWidthInput",
    "panelXValueInput", "panelYValueInput", "panelSizeValueInput", "panelMaxWidthValueInput",
    "hiddenInput"
  ]
  
  static values = {
    inputBaseName: String
  }

  connect() {
    if (!window.Interact) {
      console.error("interact.js not found. Make sure it's loaded via active_admin/javascript/application.js");
      return;
    }

    this.canvas = this.canvasTarget;
    this.image = this.frontImageTarget.offsetParent ? this.frontImageTarget : this.backImageTarget;

    const setup = () => {
      this.elementTargets.forEach(element => {
        this.setupElement(element);
      });
    };

    if (this.image && this.image.complete) {
      setup();
    } else if (this.image) {
      this.image.addEventListener('load', setup);
    }

    this.resizeListener = () => this.recalculateAllElementSizes();
    window.addEventListener('resize', this.resizeListener);
    this.initPanelDraggable();
  }

  disconnect() {
    if (this.resizeListener) {
      window.removeEventListener('resize', this.resizeListener);
    }
  }

  setupElement(element) {
    const xInput = this.findInputForElement(element, 'x');
    const yInput = this.findInputForElement(element, 'y');

    let x = parseFloat(xInput.value || 0);
    let y = parseFloat(yInput.value || 0);

    element.style.left = `${x}%`;
    element.style.top = `${y}%`;

    element.dataset.x = x;
    element.dataset.y = y;

    this.setElementSize(element);
    this.initDraggable(element);
    this.initResizable(element);
  }

  initDraggable(element) {
    window.Interact(element).draggable({
      listeners: {
        move: event => {
          const target = event.target;
          let x = parseFloat(target.dataset.x) + (event.dx * 100 / this.canvas.offsetWidth);
          let y = parseFloat(target.dataset.y) + (event.dy * 100 / this.canvas.offsetHeight);

          target.style.left = `${x}%`;
          target.style.top = `${y}%`;

          target.dataset.x = x;
          target.dataset.y = y;

          this.updateHiddenInput(target, 'x', x.toFixed(4));
          this.updateHiddenInput(target, 'y', y.toFixed(4));
        }
      },
      modifiers: [
        window.Interact.modifiers.restrictRect({
          restriction: 'parent'
        })
      ],
      inertia: false
    });
  }

  initPanelDraggable() {
    const panel = this.propertiesPanelTarget;
    panel.dataset.x = 0;
    panel.dataset.y = 0;

    window.Interact(panel).draggable({
      allowFrom: this.panelHandleTarget,
      listeners: {
        move: event => {
          let x = (parseFloat(panel.dataset.x) || 0) + event.dx;
          let y = (parseFloat(panel.dataset.y) || 0) + event.dy;

          panel.style.transform = `translate(${x}px, ${y}px)`;

          panel.dataset.x = x;
          panel.dataset.y = y;
        }
      },
      inertia: false,
      modifiers: [
        window.Interact.modifiers.restrictRect({
          restriction: 'parent',
          endOnly: true
        })
      ]
    });
  }

  
  initResizable(element) {
    const isQr = this.isQrCode(element);
    window.Interact(element).resizable({
      // Only allow vertical resizing for QR codes. Text elements can only be resized horizontally.
      edges: { left: true, right: true, bottom: isQr, top: isQr },
      listeners: {
        move: event => {
          const target = event.target;

          let x = parseFloat(target.dataset.x) + (event.deltaRect.left * 100 / this.canvas.offsetWidth);
          let y = parseFloat(target.dataset.y) + (event.deltaRect.top * 100 / this.canvas.offsetHeight);
          target.style.left = `${x}%`;
          target.style.top = `${y}%`;
          target.dataset.x = x;
          target.dataset.y = y;
          this.updateHiddenInput(target, 'x', x.toFixed(4));
          this.updateHiddenInput(target, 'y', y.toFixed(4));

          if (this.isQrCode(target)) {
            const widthPercent = event.rect.width * 100 / this.canvas.offsetWidth;
            this.updateHiddenInput(target, 'size', widthPercent.toFixed(4));
          } else {
            const maxWidthInput = this.findInputForElement(target, 'max_text_width');
            const widthPercent = (event.rect.width / this.canvas.offsetWidth) * 100;
            this.updateHiddenInput(target, 'max_text_width', widthPercent.toFixed(4));
          }
          this.setElementSize(target);
          this.updatePanel(); // Refresh panel to show new values
        }
      },
      modifiers: [
        window.Interact.modifiers.restrictEdges({ outer: 'parent' }),
        this.isQrCode(element) ? window.Interact.modifiers.aspectRatio({ ratio: 1 }) : null
      ].filter(Boolean),
      inertia: false
    });
  }

  setElementSize(element) {
    const sizeInput = this.findInputForElement(element, 'size');
    if (!sizeInput) return;

    const size = parseFloat(sizeInput.value || 10);

    if (this.isQrCode(element)) {
      element.style.width = `${size}%`;
      const elementWidthPixels = this.canvas.offsetWidth * (size / 100);
      element.style.height = `${elementWidthPixels}px`;
    } else {
      const maxWidthInput = this.findInputForElement(element, 'max_text_width');
      const maxWidthPercent = parseFloat(maxWidthInput.value || 30);
      element.style.width = `${maxWidthPercent}%`;

      // Font size is now a percentage of the canvas width, making it responsive.
      const fontSizePx = (size / 100) * this.canvas.offsetWidth;
      element.style.fontSize = `${fontSizePx}px`;

      element.style.height = 'auto';
      const calculatedHeight = element.scrollHeight;
      element.style.height = `${Math.max(calculatedHeight, fontSizePx)}px`;
    }
  }

  recalculateAllElementSizes() {
    this.elementTargets.forEach(element => {
        this.setElementSize(element);
    });
  }

  findInputForElement(element, property) {
    const elementType = element.dataset.elementType;
    return this.hiddenInputTargets.find(input =>
      input.dataset.elementType === elementType && input.dataset.property === property
    );
  }

  isQrCode(element) {
    return element.dataset.elementType.includes('qrcode');
  }

  selectElement(event) {
    event.stopPropagation();
    const target = event.currentTarget;

    this.elementTargets.forEach(el => el.classList.remove('border-green-500', 'border-solid'));

    target.classList.add('border-green-500', 'border-solid');
    this.selectedElement = target;

    this.updatePanel();
    this.propertiesPanelTarget.classList.remove('hidden');
  }

  deselect(event) {
    // This action is specifically for clicks on the canvas background.
    if (event && event.target !== this.canvasTarget) {
      return;
    }
    this.closePanel();
  }

  closePanel() {
    if (this.selectedElement) {
      this.selectedElement.classList.remove('border-green-500', 'border-solid');
      this.selectedElement = null;
    }
    this.propertiesPanelTarget.classList.add('hidden');
  }

  updatePanel() {
    if (!this.selectedElement) return;

    const elementType = this.selectedElement.dataset.elementType;
    const isQr = this.isQrCode(this.selectedElement);

    this.panelTitleTarget.textContent = elementType.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());

    // Get values from hidden inputs
    const x = this.findInputForElement(this.selectedElement, 'x').value;
    const y = this.findInputForElement(this.selectedElement, 'y').value;
    const color = this.findInputForElement(this.selectedElement, 'color').value;
    const size = this.findInputForElement(this.selectedElement, 'size').value;
    const maxWidth = this.findInputForElement(this.selectedElement, 'max_text_width').value;

    this.panelXInputTarget.value = x;
    this.panelXValueInputTarget.value = parseFloat(x).toFixed(1);

    this.panelYInputTarget.value = y;
    this.panelYValueInputTarget.value = parseFloat(y).toFixed(1);

    this.panelColorInputTarget.value = color;

    this.panelSizeInputTarget.value = size;
    this.panelSizeValueInputTarget.value = parseFloat(size).toFixed(isQr ? 1 : 2);

    this.panelMaxWidthInputTarget.value = maxWidth;
    this.panelMaxWidthValueInputTarget.value = parseFloat(maxWidth).toFixed(1);

    if (!isQr) {
      this.panelPreviewTextInputTarget.value = this.selectedElement.querySelector('p').textContent;
    }

    // Show/hide relevant containers
    this.panelMaxWidthContainerTarget.classList.toggle('hidden', isQr);
    this.panelColorContainerTarget.classList.toggle('hidden', isQr);
    this.panelPreviewTextContainerTarget.classList.toggle('hidden', isQr);

    if (isQr) {
      this.panelSizeLabelTarget.textContent = "Size (%)";
      this.panelSizeInputTarget.min = 1;
      this.panelSizeInputTarget.max = 50;
      this.panelSizeInputTarget.step = 0.01;
    } else {
      this.panelSizeLabelTarget.textContent = "Font Size (%)";
      this.panelSizeInputTarget.min = 1;
      this.panelSizeInputTarget.max = 20;
      this.panelSizeInputTarget.step = 0.01;
    }
  }

  updateFromPanel(event) {
    if (!this.selectedElement) return;

    const input = event.currentTarget;
    const property = input.dataset.property;
    const value = input.value;

    if (input.type === 'number' && (value.trim() === '' || isNaN(parseFloat(value)))) {
      const lastValue = this.findInputForElement(this.selectedElement, property).value;
      const isQr = this.isQrCode(this.selectedElement);

      if (property === 'size') {
        input.value = parseFloat(lastValue).toFixed(isQr ? 1 : 2);
      } else {
        input.value = parseFloat(lastValue).toFixed(1);
      }
      return;
    }

    this.updateHiddenInput(this.selectedElement, property, value);

    // Update UI based on the property that changed
    switch (property) {
      case 'x':
        this.selectedElement.style.left = `${value}%`;
        this.selectedElement.dataset.x = value;
        this.panelXInputTarget.value = value;
        this.panelXValueInputTarget.value = parseFloat(value).toFixed(1);
        break;
      case 'y':
        this.selectedElement.style.top = `${value}%`;
        this.selectedElement.dataset.y = value;
        this.panelYInputTarget.value = value;
        this.panelYValueInputTarget.value = parseFloat(value).toFixed(1);
        break;
      case 'color':
        this.selectedElement.style.color = value;
        break;
      case 'size':
        this.setElementSize(this.selectedElement);
        const isQr = this.isQrCode(this.selectedElement);
        this.panelSizeInputTarget.value = value;
        this.panelSizeValueInputTarget.value = parseFloat(value).toFixed(isQr ? 1 : 2);
        break;
      case 'max_text_width':
        this.setElementSize(this.selectedElement);
        this.panelMaxWidthInputTarget.value = value;
        this.panelMaxWidthValueInputTarget.value = parseFloat(value).toFixed(1);
        break;
    }
  }

  updateHiddenInput(element, property, value) {
    const hiddenInput = this.findInputForElement(element, property);
    if (hiddenInput) {
      hiddenInput.value = value;
      hiddenInput.setAttribute('value', value);
    }
  }


  updatePreviewText(event) {
    if (!this.selectedElement) return;
    const value = event.currentTarget.value;
    this.selectedElement.querySelector('p').textContent = value;
    // Recalculate height after text change
    this.setElementSize(this.selectedElement);
  }

  resetElements(event) {
    event.preventDefault();

    // Filter for elements that are currently visible on the active tab.
    const visibleElements = this.elementTargets.filter(el => !el.classList.contains('hidden'));

    visibleElements.forEach(element => {
      const propertiesToReset = {
        x: 30,
        y: 30,
        size: 30,
        max_text_width: 30
      };

      for (const property in propertiesToReset) {
        const input = this.findInputForElement(element, property);
        if (input) {
          input.value = propertiesToReset[property];
        }
      }

      // Re-apply all settings based on the new hidden input values.
      this.setupElement(element);
    });

    // If a panel is open for a selected element, update it.
    if (this.selectedElement && !this.selectedElement.classList.contains('hidden')) {
      this.updatePanel();
    }
  }
  
  switchView(event) {
    event.preventDefault();
    const tab = event.currentTarget;
    const view = tab.dataset.view;

    if (tab.classList.contains('tab-active')) return;

    if (view === 'front') {
      this.frontImageTarget.classList.remove('hidden');
      this.backImageTarget.classList.add('hidden');
      this.frontTabTarget.classList.add('tab-active');
      this.backTabTarget.classList.remove('tab-active');
      this.image = this.frontImageTarget;
    } else {
      this.frontImageTarget.classList.add('hidden');
      this.backImageTarget.classList.remove('hidden');
      this.frontTabTarget.classList.remove('tab-active');
      this.backTabTarget.classList.add('tab-active');
      this.image = this.backImageTarget;
    }

    this.elementTargets.forEach(el => {
      el.classList.toggle('hidden', el.dataset.view !== view);
    });

    this.recalculateAllElementSizes();
    this.deselect();
  }
}