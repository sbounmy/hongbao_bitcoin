import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "canvas", "element", "frontImage", "backImage", "frontTab", "backTab",
    "propertiesPanel", "panelTitle", "panelColorInput",
    "panelColorContainer", "panelOpacityContainer", "panelWidthContainer", "panelHeightContainer", "panelSizeContainer", "panelWidthLabel",
    "panelHandle", "panelPreviewTextContainer", "panelPreviewTextInput",
    "panelXInput", "panelYInput", "panelWidthInput", "panelHeightInput", "panelSizeInput", "panelOpacityInput",
    "panelXValueInput", "panelYValueInput", "panelWidthValueInput", "panelHeightValueInput", "panelSizeValueInput", "panelOpacityValueInput",
    "hiddenInput"
  ]

  static values = {
    inputBaseName: String,
    elementTypes: Object,
    elementTypeMap: Object
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
    const opacityInput = this.findInputForElement(element, 'opacity');

    let x = parseFloat(xInput.value || 0);
    let y = parseFloat(yInput.value || 0);
    let opacity = opacityInput ? parseFloat(opacityInput.value) : 1.0;

    element.style.left = `${x}%`;
    element.style.top = `${y}%`;
    element.style.opacity = opacity;

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
    const elementName = element.dataset.elementType;

    // Determine aspect ratio behavior from model configuration
    // This would ideally come from server, but we'll mirror the Ruby constants
    const aspectRatioConfig = this.getAspectRatioConfig(elementName);
    const hasFixedRatio = typeof aspectRatioConfig === 'number';
    const hasShiftKeyRatio = aspectRatioConfig === 'shift_key';

    window.Interact(element).resizable({
      // Shape elements can resize in all directions, text elements can resize in both
      edges: { left: true, right: true, bottom: true, top: true },
      listeners: {
        move: event => {
          const target = event.target;

          // Update position if element moved during resize
          let x = parseFloat(target.dataset.x) + (event.deltaRect.left * 100 / this.canvas.offsetWidth);
          let y = parseFloat(target.dataset.y) + (event.deltaRect.top * 100 / this.canvas.offsetHeight);
          target.style.left = `${x}%`;
          target.style.top = `${y}%`;
          target.dataset.x = x;
          target.dataset.y = y;
          this.updateHiddenInput(target, 'x', x.toFixed(4));
          this.updateHiddenInput(target, 'y', y.toFixed(4));

          // Update width and height
          const widthPercent = event.rect.width * 100 / this.canvas.offsetWidth;
          const heightPercent = event.rect.height * 100 / this.canvas.offsetHeight;

          this.updateHiddenInput(target, 'width', widthPercent.toFixed(4));
          this.updateHiddenInput(target, 'height', heightPercent.toFixed(4));

          this.setElementSize(target);
          this.updatePanel(); // Refresh panel to show new values
        }
      },
      modifiers: [
        window.Interact.modifiers.restrictEdges({ outer: 'parent' }),
        // Aspect ratio modifier based on element configuration
        hasFixedRatio ?
          window.Interact.modifiers.aspectRatio({ ratio: aspectRatioConfig }) :
          hasShiftKeyRatio ?
            window.Interact.modifiers.aspectRatio({ ratio: 'preserve', enabled: false }) :
            null
      ].filter(Boolean),
      inertia: false
    });

    // Handle Shift key for portrait (shift_key mode)
    if (hasShiftKeyRatio) {
      element.addEventListener('mousedown', (e) => {
        if (e.target !== element) return;

        const updateModifiers = (shiftPressed) => {
          const interaction = window.Interact(element);
          const resizable = interaction.resizable();
          if (resizable && resizable.options && resizable.options.modifiers) {
            const aspectRatioModifier = resizable.options.modifiers.find(m => m.options && m.options.ratio);
            if (aspectRatioModifier) {
              aspectRatioModifier.options.enabled = shiftPressed;
            }
          }
        };

        const handleKeyChange = (e) => {
          if (e.key === 'Shift') {
            updateModifiers(e.type === 'keydown');
          }
        };

        window.addEventListener('keydown', handleKeyChange);
        window.addEventListener('keyup', handleKeyChange);

        const cleanup = () => {
          window.removeEventListener('keydown', handleKeyChange);
          window.removeEventListener('keyup', handleKeyChange);
          window.removeEventListener('mouseup', cleanup);
        };
        window.addEventListener('mouseup', cleanup);
      });
    }
  }

  // Get aspect ratio configuration for element (mirrors Ruby ELEMENT_ASPECT_RATIOS)
  getAspectRatioConfig(elementName) {
    const config = {
      'private_key_qrcode': 1.0,
      'public_address_qrcode': 1.0,
      'portrait': 'shift_key',
      'private_key_text': null,
      'public_address_text': null,
      'mnemonic_text': null
    };
    return config[elementName] || null;
  }

  setElementSize(element) {
    const widthInput = this.findInputForElement(element, 'width');
    if (!widthInput) return;

    const widthPercent = parseFloat(widthInput.value || 10);
    element.style.width = `${widthPercent}%`;

    const elementType = this.getElementType(element);

    if (elementType === 'shape') {
      // Shape elements: width and height control dimensions
      const heightInput = this.findInputForElement(element, 'height');
      const heightPercent = parseFloat(heightInput?.value || widthPercent);

      // Calculate height in pixels based on canvas height percentage
      const heightPixels = this.canvas.offsetHeight * (heightPercent / 100);
      element.style.height = `${heightPixels}px`;
    } else {
      // Text elements: width + height create fixed bounding box, size controls font
      const heightInput = this.findInputForElement(element, 'height');
      const heightPercent = parseFloat(heightInput?.value || 10);
      const heightPixels = this.canvas.offsetHeight * (heightPercent / 100);
      element.style.height = `${heightPixels}px`;

      // Size property controls font size separately
      const sizeInput = this.findInputForElement(element, 'size');
      const sizePercent = parseFloat(sizeInput?.value || 14);
      const fontSize = (sizePercent / 100) * this.canvas.offsetWidth;
      element.style.fontSize = `${fontSize}px`;

      // Text overflow handling
      element.style.overflow = 'hidden';
      element.style.textOverflow = 'ellipsis';
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

  // Get element type (shape or text) based on element name
  getElementType(element) {
    const elementName = element.dataset.elementType;
    // Shape elements: qrcodes and portrait (should maintain aspect ratio with Shift)
    if (elementName.includes('qrcode') || elementName === 'portrait') {
      return 'shape';
    }
    // Text elements: all text-based elements
    return 'text';
  }

  // Check if element supports aspect ratio locking
  supportsAspectRatio(element) {
    return this.getElementType(element) === 'shape';
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
    const elementTypeCategory = this.getElementType(this.selectedElement);

    // Get properties configuration for this element type
    const availableProperties = this.elementTypesValue[elementTypeCategory]?.properties || [];

    this.panelTitleTarget.textContent = elementType.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());

    // Get values from hidden inputs (defaults provided by hidden_input_value helper)
    const x = this.findInputForElement(this.selectedElement, 'x').value;
    const y = this.findInputForElement(this.selectedElement, 'y').value;
    const width = this.findInputForElement(this.selectedElement, 'width').value;

    this.panelXInputTarget.value = x;
    this.panelXValueInputTarget.value = parseFloat(x).toFixed(1);

    this.panelYInputTarget.value = y;
    this.panelYValueInputTarget.value = parseFloat(y).toFixed(1);

    this.panelWidthInputTarget.value = width;
    this.panelWidthValueInputTarget.value = parseFloat(width).toFixed(1);

    // Show/hide property fields based on element configuration
    const hasColor = availableProperties.includes('color');
    const hasOpacity = availableProperties.includes('opacity');
    const hasHeight = availableProperties.includes('height');
    const hasSize = availableProperties.includes('size');

    // Color
    this.panelColorContainerTarget.classList.toggle('hidden', !hasColor);
    if (hasColor) {
      const colorInput = this.findInputForElement(this.selectedElement, 'color');
      if (colorInput?.value) {
        this.panelColorInputTarget.value = colorInput.value;
      }
    }

    // Opacity
    this.panelOpacityContainerTarget.classList.toggle('hidden', !hasOpacity);
    console.log('has:...', hasOpacity)
    if (hasOpacity) {
      const opacityInput = this.findInputForElement(this.selectedElement, 'opacity');
      if (opacityInput?.value) {
        console.log('opacity:', opacityInput)
        this.panelOpacityInputTarget.value = opacityInput.value;
        this.panelOpacityValueInputTarget.value = parseFloat(opacityInput.value).toFixed(2);
      }
    }

    // Height
    if (hasHeight) {
      const heightInput = this.findInputForElement(this.selectedElement, 'height');
      if (heightInput?.value) {
        this.panelHeightInputTarget.value = heightInput.value;
        this.panelHeightValueInputTarget.value = parseFloat(heightInput.value).toFixed(1);
      }
    }

    // Size (font size for text)
    this.panelSizeContainerTarget.classList.toggle('hidden', !hasSize);
    if (hasSize) {
      const sizeInput = this.findInputForElement(this.selectedElement, 'size');
      if (sizeInput?.value) {
        this.panelSizeInputTarget.value = sizeInput.value;
        this.panelSizeValueInputTarget.value = parseFloat(sizeInput.value).toFixed(1);
      }
    }

    // Preview text - only show for text elements (elements that have 'size' property)
    this.panelPreviewTextContainerTarget.classList.toggle('hidden', !hasSize);
    if (hasSize) {
      const textElement = this.selectedElement.querySelector('p');
      if (textElement) {
        this.panelPreviewTextInputTarget.value = textElement.textContent || '';
      }
    }

    // Update labels based on element type
    this.panelWidthLabelTarget.textContent = hasSize ? "Max Width (%)" : "Width (%)";
  }

  updateFromPanel(event) {
    if (!this.selectedElement) return;

    const input = event.currentTarget;
    const property = input.dataset.property;
    const value = input.value;

    if (input.type === 'number' && (value.trim() === '' || isNaN(parseFloat(value)))) {
      const lastValue = this.findInputForElement(this.selectedElement, property)?.value || '10';
      input.value = parseFloat(lastValue).toFixed(1);
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
      case 'opacity':
        this.selectedElement.style.opacity = value;
        this.panelOpacityInputTarget.value = value;
        this.panelOpacityValueInputTarget.value = parseFloat(value).toFixed(2);
        break;
      case 'width':
        this.setElementSize(this.selectedElement);
        this.panelWidthInputTarget.value = value;
        this.panelWidthValueInputTarget.value = parseFloat(value).toFixed(1);
        break;
      case 'height':
        this.setElementSize(this.selectedElement);
        this.panelHeightInputTarget.value = value;
        this.panelHeightValueInputTarget.value = parseFloat(value).toFixed(1);
        break;
      case 'size':
        this.setElementSize(this.selectedElement);
        this.panelSizeInputTarget.value = value;
        this.panelSizeValueInputTarget.value = parseFloat(value).toFixed(1);
        break;
    }
  }

  preventSubmitOnEnter(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      event.currentTarget.blur(); // De-focus the input, which also triggers the 'change' event
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
        width: 30,
        height: 30,
        size: 14
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