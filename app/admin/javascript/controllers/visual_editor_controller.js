import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "element", "propertiesPanel", "propertiesContent", "sideSelector"]
  static values = { 
    elementTypes: Array,
    modelType: { type: String, default: "theme" }
  }
  
  connect() {
    console.log("Visual editor controller connected", this.element)
    if (this.element.classList.contains('visual-editor-container')) {
      this.currentSide = "front"
      this.setupSideSelector()
      this.initializeCanvas()
      this.initializeElements()
      this.setupInteractJS()
      this.setupFormInputListeners()
    }
  }

  disconnect() {
    // Clean up event listeners
    if (this.formInputListeners) {
      this.formInputListeners.forEach(({ element, handler, event }) => {
        element.removeEventListener(event, handler)
      })
    }
    
    this.elementTargets.forEach(element => {
      if (element._interact) {
        window.Interact(element).unset()
      }
    })
  }

  // Define which elements belong to which side
  getElementsForSide(side) {
    if (side === "front") {
      return ['public_address_qrcode', 'public_address_text']
    } else { // back
      return ['private_key_qrcode', 'private_key_text', 'mnemonic_text']
    }
  }

  getSideForElement(elementType) {
    if (['public_address_qrcode', 'public_address_text'].includes(elementType)) {
      return 'front'
    } else {
      return 'back'
    }
  }

  isElementVisibleOnCurrentSide(elementType) {
    const elementsForCurrentSide = this.getElementsForSide(this.currentSide)
    return elementsForCurrentSide.includes(elementType)
  }

  isSquareElement(elementType) {
    const squareElements = ['private_key_qrcode', 'public_address_qrcode']
    return squareElements.includes(elementType)
  }

  isTextElement(elementType) {
    const textElements = ['private_key_text', 'public_address_text', 'mnemonic_text']
    return textElements.includes(elementType)
  }

  getFormFieldName(elementType, property) {
    if (this.modelTypeValue === "theme") {
      return `input_theme[ai][${elementType}][${property}]`
    } else {
      return `paper[elements][${elementType}][${property}]`
    }
  }

  loadImageForCurrentSide() {
    let imageInput;
    
    if (this.modelTypeValue === "theme") {
      imageInput = document.querySelector(`input[id*="input_theme_${this.currentSide}_image"]`)
    } else {
      imageInput = document.querySelector(`input[id*="paper_image_${this.currentSide}"]`)
    }
    
    console.log(`Loading ${this.currentSide} image for ${this.modelTypeValue}`, imageInput)
    
    if (imageInput && imageInput.files && imageInput.files[0]) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.setCanvasBackground(e.target.result)
      }
      reader.readAsDataURL(imageInput.files[0])
    } else {
      const hint = imageInput?.parentNode?.querySelector('.inline-hints')
      if (hint && hint.querySelector('img')) {
        const existingImageSrc = hint.querySelector('img').src
        this.setCanvasBackground(existingImageSrc)
      }
    }
  }

  initializeCanvas() {
    this.loadImageForCurrentSide()
    
    ['front', 'back'].forEach(side => {
      let imageInput;
      if (this.modelTypeValue === "theme") {
        imageInput = document.querySelector(`input[id*="input_theme_${side}_image"]`)
      } else {
        imageInput = document.querySelector(`input[id*="paper_image_${side}"]`)
      }
      
      if (imageInput) {
        imageInput.addEventListener('change', (e) => {
          if (e.target.files && e.target.files[0] && this.currentSide === side) {
            const reader = new FileReader()
            reader.onload = (event) => {
              this.setCanvasBackground(event.target.result)
            }
            reader.readAsDataURL(e.target.files[0])
          }
        })
      }
    })
  }

  setupSideSelector() {
    if (this.hasSideSelectorTarget) {
      this.updateSideSelectorButtons()
      this.updateElementVisibility()
    }
  }

  switchToFront(event) {
    event.preventDefault()
    this.currentSide = "front"
    this.loadImageForCurrentSide()
    this.updateElementVisibility()
    this.initializeElements()
    this.updateSideSelectorButtons()
    this.closeProperties()
    console.log("Switched to front side - showing public address elements")
  }

  switchToBack(event) {
    event.preventDefault()
    this.currentSide = "back"
    this.loadImageForCurrentSide()
    this.updateElementVisibility()
    this.initializeElements()
    this.updateSideSelectorButtons()
    this.closeProperties()
    console.log("Switched to back side - showing private key and mnemonic elements")
  }

  updateElementVisibility() {
    this.elementTargets.forEach(element => {
      const elementType = element.dataset.elementType
      const shouldBeVisible = this.isElementVisibleOnCurrentSide(elementType)
      
      if (shouldBeVisible) {
        element.style.display = 'flex'
        element.classList.remove('opacity-50')
      } else {
        element.style.display = 'none'
      }
    })
    
    if (!this.propertiesPanelTarget.classList.contains('hidden')) {
      const selectedElement = this.elementTargets.find(el => el.classList.contains('selected'))
      if (selectedElement && !this.isElementVisibleOnCurrentSide(selectedElement.dataset.elementType)) {
        this.closeProperties()
      }
    }
  }

  updateSideSelectorButtons() {
    if (!this.hasSideSelectorTarget) return
    
    const frontBtn = this.sideSelectorTarget.querySelector('[data-side="front"]')
    const backBtn = this.sideSelectorTarget.querySelector('[data-side="back"]')
    
    if (frontBtn && backBtn) {
      if (this.currentSide === 'front') {
        frontBtn.classList.remove('bg-gray-500')
        frontBtn.classList.add('bg-blue-500')
        backBtn.classList.remove('bg-blue-500')
        backBtn.classList.add('bg-gray-500')
      } else {
        frontBtn.classList.remove('bg-blue-500')
        frontBtn.classList.add('bg-gray-500')
        backBtn.classList.remove('bg-gray-500')
        backBtn.classList.add('bg-blue-500')
      }
      
      frontBtn.textContent = 'Front (Public Address)'
      backBtn.textContent = 'Back (Private Key & Mnemonic)'
    }
  }

  // IMPROVED: Better form input listeners with debouncing and proper cleanup
  setupFormInputListeners() {
    const elementTypes = this.elementTypesValue
    this.formInputListeners = []
    
    console.log("Setting up form input listeners for element types:", elementTypes)
    
    elementTypes.forEach(elementType => {
      ['x', 'y', 'size', 'color', 'max_text_width'].forEach(property => {
        const fieldName = this.getFormFieldName(elementType, property)
        const input = document.querySelector(`input[name="${fieldName}"]`)
        
        if (input) {
          // Create handlers for both input and change events
          const updateHandler = (e) => {
            const value = e.target.value
            console.log(`Manual form input change: ${elementType}.${property} = ${value}`)
            
            // Update visual element immediately
            this.handleManualFormInputChange(elementType, property, value)
          }
          
          // Add event listeners
          input.addEventListener('input', updateHandler)
          input.addEventListener('change', updateHandler)
          input.addEventListener('keyup', updateHandler)  // Also listen for keyup
          
          // Store for cleanup
          this.formInputListeners.push(
            { element: input, handler: updateHandler, event: 'input' },
            { element: input, handler: updateHandler, event: 'change' },
            { element: input, handler: updateHandler, event: 'keyup' }
          )
          
          console.log(`Added listeners for ${fieldName}`)
        } else {
          console.warn(`Form input not found: ${fieldName}`)
        }
      })
    })
    
    console.log(`Total form input listeners added: ${this.formInputListeners.length}`)
  }

  // NEW: Handle manual form input changes (from typing in form fields)
  handleManualFormInputChange(elementType, property, value) {
  console.log(`Processing manual change: ${elementType}.${property} = ${value}`)
  
  // Only update visual elements that are visible on current side
  if (!this.isElementVisibleOnCurrentSide(elementType)) {
    console.log(`Skipping update for ${elementType} - not visible on ${this.currentSide} side`)
    return
  }

  const element = this.elementTargets.find(el => el.dataset.elementType === elementType)
  if (!element) {
    console.warn(`Visual element not found: ${elementType}`)
    return
  }

  console.log(`Updating visual element ${elementType}.${property} to ${value}`)

  // Update the visual element immediately
  this.updateVisualElementFromFormValue(element, elementType, property, value)
  
  // If the properties panel is open for this element, update it too
  if (!this.propertiesPanelTarget.classList.contains('hidden')) {
    const selectedElement = this.elementTargets.find(el => el.classList.contains('selected'))
    if (selectedElement && selectedElement.dataset.elementType === elementType) {
      // Don't refresh the properties panel as it would interrupt typing
      // this.refreshPropertiesPanel(elementType)
    }
  }
}

  // NEW: Update visual element from a specific form value
  updateVisualElementFromFormValue(element, elementType, property, value) {
    const originalWidth = this.originalImageWidth || this.canvasTarget.offsetWidth
    const originalHeight = this.originalImageHeight || this.canvasTarget.offsetHeight
    console.log(originalHeight);
    console.log(originalWidth)
    const displayWidth = this.canvasTarget.offsetWidth
    const displayHeight = this.canvasTarget.offsetHeight
    const scaleX = displayWidth / originalWidth
    const scaleY = displayHeight / originalHeight
    
    switch(property) {
      case 'x':
        const originalX = (parseFloat(value) || 0) * originalWidth / 100
        const displayX = originalX * scaleX
        element.style.left = `${Math.max(0, Math.min(displayWidth - element.offsetWidth, displayX))}px`
        break
        
      case 'y':
        const originalY = (parseFloat(value) || 0) * originalHeight / 100
        const displayY = originalY * scaleY
        element.style.top = `${Math.max(0, Math.min(displayHeight - element.offsetHeight, displayY))}px`
        break
        
      case 'size':
        if (this.isTextElement(elementType)) {
          const originalFontSize = Math.max(2, Math.min(72, parseFloat(value) || 12))
          const displayFontSize = originalFontSize * Math.min(scaleX, scaleY)
          this.updateTextElementSize(element, displayFontSize, parseFloat(element.style.maxWidth) || 0)
        } else {
          const originalSize = (parseFloat(value) || 10) * Math.min(originalWidth, originalHeight) / 100
          const displaySize = originalSize * Math.min(scaleX, scaleY)
          const constrainedSize = Math.max(20, Math.min(200, displaySize))
          
          element.style.width = `${constrainedSize}px`
          element.style.height = `${constrainedSize}px`
        }
        
        // Ensure element stays within bounds
        this.constrainElementToBounds(element, displayWidth, displayHeight)
        break
        
      case 'color':
        if (value) {
          element.style.borderColor = value
          element.style.backgroundColor = this.hexToRgba(value, 0.1)
          element.style.color = value
        }
        break
        
      case 'max_text_width':
        if (this.isTextElement(elementType) && value) {
          const originalMaxWidth = parseFloat(value)
          const displayMaxWidth = originalMaxWidth * scaleX
          const fontSize = parseFloat(element.style.fontSize) || 8
          this.updateTextElementSize(element, fontSize, displayMaxWidth)
        }
        break
    }
    
    // Refresh InteractJS after visual changes
    this.refreshInteractJS(element)
  }

  // NEW: Constrain element to canvas bounds
  constrainElementToBounds(element, displayWidth, displayHeight) {
    const currentLeft = parseFloat(element.style.left) || 0
    const currentTop = parseFloat(element.style.top) || 0
    
    if (currentLeft + element.offsetWidth > displayWidth) {
      element.style.left = `${displayWidth - element.offsetWidth}px`
    }
    if (currentTop + element.offsetHeight > displayHeight) {
      element.style.top = `${displayHeight - element.offsetHeight}px`
    }
  }

  // NEW: Refresh InteractJS for a specific element
  refreshInteractJS(element) {
    if (element._interact) {
      window.Interact(element).unset()
    }
    
    const elementType = element.dataset.elementType
    if (this.isElementVisibleOnCurrentSide(elementType)) {
      this.setupSingleElementInteract(element, elementType)
    }
  }

  // NEW: Refresh properties panel content
  refreshPropertiesPanel(elementType) {
    // Small delay to ensure form values are updated
    setTimeout(() => {
      this.showPropertiesPanel(elementType)
    }, 50)
  }

  // NEW: Debounce utility
  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }

  // EXISTING: Keep the original handleFormInputChange for backward compatibility
  handleFormInputChange(elementType, property, value) {
    this.handleManualFormInputChange(elementType, property, value)
  }
  
  updateTextElementSize(element, fontSize, maxTextWidth) {
    element.style.fontSize = `${fontSize}px`
    
    if (maxTextWidth > 0) {
      element.style.maxWidth = `${maxTextWidth}px`
      element.style.whiteSpace = 'normal'
      element.style.wordWrap = 'break-word'
      element.style.width = `${maxTextWidth}px`
    } else {
      const textLength = element.textContent.length
      const calculatedWidth = Math.max(50, fontSize * textLength * 0.6)
      element.style.width = `${calculatedWidth}px`
    }
    
    element.style.height = `${fontSize * 1.5}px`
  } 

  // Update the setFixedCanvasSize method:

  setFixedCanvasSize() {
    // SMALLER: 600x300 pixels (2:1 ratio) - more reasonable size
    this.canvasTarget.style.width = '600px'
    this.canvasTarget.style.height = '300px'
    this.canvasTarget.style.minWidth = '600px'
    this.canvasTarget.style.minHeight = '300px'
    this.canvasTarget.style.maxWidth = '600px'
    this.canvasTarget.style.maxHeight = '300px'
    
    // Other styles
    this.canvasTarget.style.backgroundSize = 'cover'
    this.canvasTarget.style.backgroundRepeat = 'no-repeat'
    this.canvasTarget.style.backgroundPosition = 'center'
    this.canvasTarget.style.padding = '0'
    this.canvasTarget.style.margin = '0'
    this.canvasTarget.style.border = 'none'
    this.canvasTarget.style.boxSizing = 'border-box'
    
    // Always use 1024x512 for coordinate calculations
    this.originalImageWidth = 1024
    this.originalImageHeight = 512
    
    console.log(`Fixed canvas size: 600×300 pixels, Coordinates based on: ${this.originalImageWidth}×${this.originalImageHeight}`)
}

  setDefaultCanvasSize() {
    this.setFixedCanvasSize()
    this.canvasTarget.style.backgroundColor = '#f3f4f6'
    
    setTimeout(() => {
      this.initializeElements()
      this.setupInteractJS()
    }, 100)
  }
    
  setCanvasBackground(imageSrc) {
    this.canvasTarget.style.backgroundImage = `url(${imageSrc})`
    
    // Only calculate canvas size once, or if it hasn't been set yet
    if (!this.canvasWidth || !this.canvasHeight) {
      const containerWidth = this.canvasTarget.parentElement.offsetWidth
      const maxCanvasWidth = Math.min(containerWidth - 40, 1200)
      
      // Store the calculated dimensions
      this.canvasWidth = maxCanvasWidth
      this.canvasHeight = maxCanvasWidth / 2  // Force 2:1 ratio (1024:512)
    }
    
    const img = new Image()
    img.onload = () => {
      // Always use 1024x512 as the original dimensions for coordinate calculations
      this.originalImageWidth = 1024
      this.originalImageHeight = 512
      
      // Use the stored canvas dimensions (don't recalculate)
      this.canvasTarget.style.width = `${this.canvasWidth}px`
      this.canvasTarget.style.height = `${this.canvasHeight}px`
      this.canvasTarget.style.backgroundSize = 'cover'  // CHANGED: cover instead of contain
      this.canvasTarget.style.backgroundRepeat = 'no-repeat'
      this.canvasTarget.style.backgroundPosition = 'center'
      this.canvasTarget.style.padding = '0'  // ADDED: Remove any padding
      this.canvasTarget.style.margin = '0'   // ADDED: Remove any margin
      this.canvasTarget.style.border = 'none' // ADDED: Remove border if any
      
      console.log(`Canvas: ${this.canvasWidth}×${this.canvasHeight} (display), Original coordinates: ${this.originalImageWidth}×${this.originalImageHeight}`)
      console.log(`Scale factors: X=${this.canvasWidth/this.originalImageWidth}, Y=${this.canvasHeight/this.originalImageHeight}`)
      
      setTimeout(() => {
        this.updateElementVisibility()
        this.initializeElements()
        this.setupInteractJS()
      }, 100)
    }
    
    img.onerror = () => {
      console.error('Failed to load image:', imageSrc)
      this.setDefaultCanvasSize()
    }
    
    img.src = imageSrc
  }
    

  
  initializeElements() {
    this.elementTargets.forEach(element => {
      const elementType = element.dataset.elementType
      
      if (this.isElementVisibleOnCurrentSide(elementType)) {
        this.updateElementFromForm(element, elementType)
      }
    })
  }
  
  updateElementFromForm(element, elementType) {
    if (!this.isElementVisibleOnCurrentSide(elementType)) return
    
    const formData = this.getFormData(elementType)
    
    // Use defaults if form data is empty
    const defaultData = this.getDefaultElementData(elementType)
    const x = formData.x !== '' ? parseFloat(formData.x) : defaultData.x
    const y = formData.y !== '' ? parseFloat(formData.y) : defaultData.y
    const size = formData.size !== '' ? parseFloat(formData.size) : defaultData.size
    const color = formData.color || defaultData.color
    const maxTextWidth = formData.max_text_width !== '' ? parseFloat(formData.max_text_width) : defaultData.max_text_width
    
    const originalWidth = this.originalImageWidth || this.canvasTarget.offsetWidth
    const originalHeight = this.originalImageHeight || this.canvasTarget.offsetHeight
    
    const displayWidth = this.canvasTarget.offsetWidth
    const displayHeight = this.canvasTarget.offsetHeight
    const scaleX = displayWidth / originalWidth
    const scaleY = displayHeight / originalHeight
    
    const originalX = x * originalWidth / 100
    const originalY = y * originalHeight / 100
    const displayX = originalX * scaleX
    const displayY = originalY * scaleY
    
    element.style.left = `${displayX}px`
    element.style.top = `${displayY}px`
    
    if (this.isTextElement(elementType)) {
      const originalFontSize = Math.max(2, Math.min(72, size))
      const displayFontSize = originalFontSize * Math.min(scaleX, scaleY)
      
      let displayMaxTextWidth = 0
      if (maxTextWidth) {
        displayMaxTextWidth = maxTextWidth * scaleX
      }
      
      this.updateTextElementSize(element, displayFontSize, displayMaxTextWidth)
    } else {
      const originalSize = size * Math.min(originalWidth, originalHeight) / 100
      const displaySize = originalSize * Math.min(scaleX, scaleY)
      
      element.style.width = `${displaySize}px`
      element.style.height = `${displaySize}px`
    }
    
    if (color) {
      element.style.borderColor = color
      element.style.backgroundColor = this.hexToRgba(color, 0.1)
      element.style.color = color
    }
  }
  
  getDefaultElementData(elementType) {
    const defaults = {
      'public_address_qrcode': { x: 10, y: 10, size: 15, color: '#007cba', max_text_width: 0 },
      'public_address_text': { x: 10, y: 30, size: 12, color: '#000000', max_text_width: 200 },
      'private_key_qrcode': { x: 60, y: 10, size: 15, color: '#007cba', max_text_width: 0 },
      'private_key_text': { x: 60, y: 30, size: 10, color: '#000000', max_text_width: 180 },
      'mnemonic_text': { x: 20, y: 60, size: 8, color: '#000000', max_text_width: 300 }
    }
    
    return defaults[elementType] || { x: 10, y: 10, size: 12, color: '#000000', max_text_width: 100 }
  }
  
  setupInteractJS() {
    this.elementTargets.forEach(element => {
      const elementType = element.dataset.elementType
      
      if (!this.isElementVisibleOnCurrentSide(elementType)) {
        if (element._interact) {
          window.Interact(element).unset()
        }
        return
      }
      
      this.setupSingleElementInteract(element, elementType)
    })
  }

  // NEW: Setup InteractJS for a single element
  setupSingleElementInteract(element, elementType) {
    if (element._interact) {
      window.Interact(element).unset()
    }
    
    if (this.isTextElement(elementType)) {
      element.dataset.initialWidth = element.offsetWidth
      element.dataset.initialHeight = element.offsetHeight
    }
    
    let resizeOptions = {
      edges: { right: true, bottom: true },
      listeners: {
        start: (event) => this.handleResizeStart(event),
        move: (event) => this.handleResize(event)
      },
      modifiers: [
        window.Interact.modifiers.restrictSize({
          min: { width: 20, height: 20 }
        })
      ]
    }
    
    if (this.isSquareElement(elementType)) {
      resizeOptions.modifiers.push(
        window.Interact.modifiers.aspectRatio({
          ratio: 1,
          equalDelta: false,
          modifiers: [
            window.Interact.modifiers.restrictSize({
              min: { width: 20, height: 20 }
            })
          ]
        })
      )
    }
    
    if (this.isTextElement(elementType)) {
      resizeOptions.modifiers = [
        window.Interact.modifiers.restrictSize({
          min: { width: 30, height: 10 },
          max: { width: 800, height: 150 }
        })
      ]
    }
    
    window.Interact(element)
      .draggable({
        listeners: {
          move: (event) => this.handleDrag(event)
        },
        modifiers: [
          window.Interact.modifiers.restrict({
            restriction: this.canvasTarget
          })
        ]
      })
      .resizable(resizeOptions)
      .on('tap', (event) => this.handleElementClick(event))
  }
  
  handleResizeStart(event) {
    const element = event.target
    const elementType = element.dataset.elementType
    
    if (this.isTextElement(elementType)) {
      element.dataset.initialWidth = element.offsetWidth
      element.dataset.initialHeight = element.offsetHeight
      element.dataset.initialFontSize = parseFloat(element.style.fontSize) || 8
      element.dataset.initialMaxWidth = parseFloat(element.style.maxWidth) || element.offsetWidth
    }
  }
  
  handleDrag(event) {
    const element = event.target
    const elementType = element.dataset.elementType
    
    let x = (parseFloat(element.style.left) || 0) + event.dx
    let y = (parseFloat(element.style.top) || 0) + event.dy
    
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    const elementRect = element.getBoundingClientRect()
    
    x = Math.max(0, Math.min(canvasRect.width - elementRect.width, x))
    y = Math.max(0, Math.min(canvasRect.height - elementRect.height, y))
    
    element.style.left = `${x}px`
    element.style.top = `${y}px`
    
    this.updateFormFromElement(element, elementType)
  }
  
  handleResize(event) {
    const element = event.target
    const elementType = element.dataset.elementType
    
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    const currentLeft = parseFloat(element.style.left) || 0
    const currentTop = parseFloat(element.style.top) || 0
    
    let newWidth = event.rect.width
    let newHeight = event.rect.height
    
    if (this.isTextElement(elementType)) {
      const initialWidth = parseFloat(element.dataset.initialWidth) || element.offsetWidth
      const initialHeight = parseFloat(element.dataset.initialHeight) || element.offsetHeight
      const initialFontSize = parseFloat(element.dataset.initialFontSize) || 8
      const initialMaxWidth = parseFloat(element.dataset.initialMaxWidth) || newWidth
      
      const widthChange = newWidth - initialWidth
      const heightChange = newHeight - initialHeight
      
      const isHorizontalResize = Math.abs(widthChange) > Math.abs(heightChange)
      
      let newFontSize = initialFontSize
      let maxTextWidth = initialMaxWidth
      
      if (isHorizontalResize) {
        maxTextWidth = Math.max(50, Math.min(800, newWidth))
        newFontSize = initialFontSize
      } else {
        const fontSizeRatio = newHeight / initialHeight
        newFontSize = Math.max(2, Math.min(72, initialFontSize * fontSizeRatio))
        maxTextWidth = initialMaxWidth
      }
      
      this.updateTextElementSize(element, newFontSize, maxTextWidth)
      
      const scaleX = this.canvasTarget.offsetWidth / (this.originalImageWidth || this.canvasTarget.offsetWidth)
      const scaleY = this.canvasTarget.offsetHeight / (this.originalImageHeight || this.canvasTarget.offsetHeight)
      
      const originalFontSize = newFontSize / Math.min(scaleX, scaleY)
      const originalMaxWidth = maxTextWidth / scaleX
      
      this.setFormValue(elementType, 'size', originalFontSize.toFixed(2))
      this.setFormValue(elementType, 'max_text_width', originalMaxWidth.toFixed(0))
      
    } else {
      if (this.isSquareElement(elementType)) {
        const newSize = Math.min(newWidth, newHeight)
        newWidth = newSize
        newHeight = newSize
      }
      
      const maxWidth = canvasRect.width - currentLeft
      const maxHeight = canvasRect.height - currentTop
      
      newWidth = Math.min(newWidth, maxWidth)
      newHeight = Math.min(newHeight, maxHeight)
      
      if (this.isSquareElement(elementType)) {
        const constrainedSize = Math.min(newWidth, newHeight)
        newWidth = constrainedSize
        newHeight = constrainedSize
      }
      
      newWidth = Math.max(20, newWidth)
      newHeight = Math.max(20, newHeight)
      
      if (this.isSquareElement(elementType)) {
        const minSize = Math.max(20, Math.min(newWidth, newHeight))
        newWidth = minSize
        newHeight = minSize
      }
      
      element.style.width = `${newWidth}px`
      element.style.height = `${newHeight}px`
    }
    
    this.updateFormFromElement(element, elementType)
  }
  
  handleElementClick(event) {
    event.stopPropagation()
    const element = event.currentTarget
    const elementType = element.dataset.elementType
    
    if (!this.isElementVisibleOnCurrentSide(elementType)) return
    
    this.elementTargets.forEach(el => {
      el.classList.remove('selected', 'border-orange-500', 'bg-orange-100', 'shadow-lg')
      el.classList.add('border-blue-500', 'bg-blue-50')
    })
    
    element.classList.add('selected', 'border-orange-500', 'bg-orange-100', 'shadow-lg')
    element.classList.remove('border-blue-500', 'bg-blue-50')
    
    this.showPropertiesPanel(elementType)
  }
  
  updateFormFromElement(element, elementType) {
    const displayWidth = this.canvasTarget.offsetWidth
    const displayHeight = this.canvasTarget.offsetHeight
    const originalWidth = this.originalImageWidth || displayWidth
    const originalHeight = this.originalImageHeight || displayHeight
    
    const scaleX = displayWidth / originalWidth
    const scaleY = displayHeight / originalHeight
    
    const displayX = element.offsetLeft
    const displayY = element.offsetTop
    const originalX = displayX / scaleX
    const originalY = displayY / scaleY
    
    const x = (originalX / originalWidth) * 100
    const y = (originalY / originalHeight) * 100
    
    let sizeValue
    if (this.isTextElement(elementType)) {
      const displayFontSize = parseFloat(element.style.fontSize) || 8
      const originalFontSize = displayFontSize / Math.min(scaleX, scaleY)
      sizeValue = originalFontSize
    } else {
      const displaySize = Math.min(element.offsetWidth, element.offsetHeight)
      const originalSize = displaySize / Math.min(scaleX, scaleY)
      sizeValue = (originalSize / Math.min(originalWidth, originalHeight)) * 100
    }
    
    const boundedX = Math.max(0, Math.min(100, x))
    const boundedY = Math.max(0, Math.min(100, y))
    
    let boundedSize
    if (this.isTextElement(elementType)) {
      boundedSize = Math.max(2, Math.min(72, sizeValue))
    } else {
      boundedSize = Math.max(1, Math.min(50, sizeValue))
    }
    
    this.setFormValue(elementType, 'x', boundedX.toFixed(2))
    this.setFormValue(elementType, 'y', boundedY.toFixed(2))
    this.setFormValue(elementType, 'size', boundedSize.toFixed(2))
    
    if (this.isTextElement(elementType)) {
      const displayMaxWidth = parseFloat(element.style.maxWidth) || 0
      if (displayMaxWidth > 0) {
        const originalMaxWidth = displayMaxWidth / scaleX
        this.setFormValue(elementType, 'max_text_width', originalMaxWidth.toFixed(0))
      }
    }
  }
  
  showPropertiesPanel(elementType) {
    const formData = this.getFormData(elementType)
    
    const isSquare = this.isSquareElement(elementType)
    const isText = this.isTextElement(elementType)
    
    let elementDescription = ""
    if (isSquare) {
      elementDescription = " (Square QR Code)"
    } else if (isText) {
      elementDescription = " (Text Element)"
    }
    
    const sizeLabel = isText ? "Font Size" : "Size"
    const sizeUnit = isText ? "px" : "%"
    const sizePlaceholder = isText ? "font size in pixels" : "percentage of canvas"
    
    const sideInfo = `<div class="text-xs text-purple-600 mb-2">📄 ${this.currentSide.toUpperCase()} side</div>`
    const elementsOnSide = this.getElementsForSide(this.currentSide)
    const elementContext = `<div class="text-xs text-blue-600 mb-2">Elements on ${this.currentSide}: ${elementsOnSide.map(e => e.replace(/_/g, ' ')).join(', ')}</div>`
    
    this.propertiesContentTarget.innerHTML = `
      ${sideInfo}
      ${elementContext}
      <div class="mb-3">
        <label class="block text-xs font-semibold text-gray-700 mb-1">Element</label>
        <div class="text-sm text-gray-900 bg-gray-50 px-2 py-1 rounded border">
          ${elementType.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}${elementDescription}
        </div>
      </div>
      <div class="mb-3">
        <label class="block text-xs font-semibold text-gray-700 mb-1">Color</label>
        <input type="color" 
               value="${formData.color || '#007cba'}" 
               data-action="change->visual-editor#updateElementColor"
               data-element-type="${elementType}"
               class="w-full h-8 border border-gray-300 rounded cursor-pointer">
      </div>
      <div class="mb-3">
        <label class="block text-xs font-semibold text-gray-700 mb-1">${sizeLabel}</label>
        <div class="relative">
          <input type="number" 
                 value="${formData.size || ''}" 
                 data-action="change->visual-editor#updateElementProperty"
                 data-element-type="${elementType}"
                 data-property="size"
                 placeholder="${sizePlaceholder}"
                 ${isText ? 'min="2" max="72"' : 'min="1" max="50" step="0.1"'}
                 class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none">
          <span class="absolute right-2 top-1 text-xs text-gray-400">${sizeUnit}</span>
        </div>
      </div>
      ${isText ? `
      <div class="mb-3">
        <label class="block text-xs font-semibold text-gray-700 mb-1">Max Text Width</label>
        <div class="relative">
          <input type="number" 
                 value="${formData.max_text_width || ''}" 
                 data-action="change->visual-editor#updateElementProperty"
                 data-element-type="${elementType}"
                 data-property="max_text_width"
                 placeholder="pixels"
                 class="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none">
          <span class="absolute right-2 top-1 text-xs text-gray-400">px</span>
        </div>
      </div>
      ` : ''}
      <div class="text-xs text-blue-600 mt-2">
        ${isSquare ? '💡 This element maintains a square aspect ratio' : ''}
        ${isText ? '💡 Drag vertically to resize font, horizontally to set max width.' : ''}
        ${!isSquare && !isText ? '💡 Drag corners to resize, drag to move' : ''}
      </div>
    `
    
    this.propertiesPanelTarget.classList.remove('hidden')
    this.propertiesPanelTarget.classList.add('block')
  }
  
  updateElementColor(event) {
    const color = event.target.value
    const elementType = event.target.dataset.elementType
    
    const element = this.elementTargets.find(el => el.dataset.elementType === elementType)
    if (element) {
      element.style.borderColor = color
      element.style.backgroundColor = this.hexToRgba(color, 0.1)
      element.style.color = color
    }
    
    this.setFormValue(elementType, 'color', color)
  }
  
  updateElementProperty(event) {
    const value = event.target.value
    const elementType = event.target.dataset.elementType
    const property = event.target.dataset.property
    
    this.setFormValue(elementType, property, value)
    
    if (property === 'size' || property === 'max_text_width') {
      this.handleFormInputChange(elementType, property, value)
    }
  }
  
  closeProperties() {
    this.propertiesPanelTarget.classList.add('hidden')
    this.propertiesPanelTarget.classList.remove('block')
    this.elementTargets.forEach(el => el.classList.remove('selected'))
  }
  
  getFormData(elementType) {
    const data = {}
    const properties = ['x', 'y', 'size', 'color', 'max_text_width']
    
    properties.forEach(prop => {
      const fieldName = this.getFormFieldName(elementType, prop)
      const input = document.querySelector(`input[name="${fieldName}"]`)
      if (input) {
        data[prop] = input.value
      }
    })
    
    return data
  }
  
  setFormValue(elementType, property, value) {
    const fieldName = this.getFormFieldName(elementType, property)
    const input = document.querySelector(`input[name="${fieldName}"]`)
    if (input) {
      input.value = value
      input.dispatchEvent(new Event('change', { bubbles: true }))
    }
  }
  
  hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }
}