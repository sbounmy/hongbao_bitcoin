import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "imagePreview", "customText", "occasion", "results"]

  connect() {
    this.maxFiles = 1
  }

  triggerFileInput() {
    this.fileInputTarget.click()
  }

  handleFileUpload(event) {
    const files = Array.from(event.target.files)

    // Validate number of files
    if (files.length > this.maxFiles) {
      alert(`Please select up to ${this.maxFiles} images`)
      this.fileInputTarget.value = ''
      return
    }

    // Validate file types
    const invalidFiles = files.filter(file => !file.type.startsWith('image/'))
    if (invalidFiles.length > 0) {
      alert('Please select only image files')
      this.fileInputTarget.value = ''
      return
    }

    // Clear previous previews
    this.imagePreviewTarget.innerHTML = ''

    // Create previews
    files.forEach(file => {
      const reader = new FileReader()

      reader.onload = (e) => {
        const preview = document.createElement('div')
        preview.className = 'relative aspect-square'

        preview.innerHTML = `
          <img src="${e.target.result}"
               class="w-full h-full object-cover rounded-lg"
               alt="Preview">
          <button type="button"
                  class="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-full hover:bg-red-600"
                  onclick="this.closest('.relative').remove()">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        `

        this.imagePreviewTarget.appendChild(preview)
      }

      reader.readAsDataURL(file)
    })
  }

  async generate() {
    const formData = new FormData()

    // Add files if any are selected
    if (this.hasFileInputTarget) {
      Array.from(this.fileInputTarget.files).forEach((file) => {
        formData.append('images[]', file)
      })
    }

    // Add other form data
    formData.append('prompt', this.customTextTarget.value)
    formData.append('occasion', this.occasionTarget.value)

    try {
      const response = await fetch('/leonardo_datasets/generate_design', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData,
        // Add these options to handle redirects properly
        redirect: 'follow',
        credentials: 'same-origin'
      })

      // Check if we got redirected to the login page
      if (response.redirected) {
        window.location.href = response.url
        return
      }

      const data = await response.json()

      if (response.ok) {
        this.displayResults(data.image_urls)
      } else {
        throw new Error(data.error || 'Failed to generate designs')
      }
    } catch (error) {
      console.error('Error generating designs:', error)
      alert(error.message)
    }
  }

  displayResults(imageUrls) {
    this.resultsTarget.innerHTML = imageUrls.map(url => `
      <div class="relative aspect-square">
        <img src="${url}"
             class="w-full h-full object-cover rounded-lg"
             alt="Generated design">
      </div>
    `).join('')
  }
}