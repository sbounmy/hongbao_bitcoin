import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer()

export default class extends Controller {
  static targets = ["fileInput", "imagePreview", "customText", "occasion", "results", "generateButton", "buttonText", "loadingText"]
  static values = { generationId: String }

  connect() {
    console.log("AI Design controller connected")
    this.maxFiles = 1
    this.channel = null
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
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

  async generate(event) {
    event.preventDefault()
    this.setLoading(true)

    try {
      const response = await fetch("/ai_designs/generate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({
          prompt: this.customTextTarget.value,
          occasion: this.occasionTarget.value
        })
      })

      const data = await response.json()
      console.log("Generation response:", data)

      if (data.success) {
        console.log("Subscribing to updates with signed stream name:", data.stream_name)
        this.subscribeToUpdates(data.generation_id, data.stream_name)
      } else {
        throw new Error(data.error || 'Failed to generate image')
      }

    } catch (error) {
      console.error('Error generating designs:', error)
      alert(error.message || 'Failed to generate design. Please try again.')
    } finally {
      this.setLoading(false)
    }
  }

  subscribeToUpdates(generationId, signedStreamName) {
    console.log("Setting up subscription for generation:", generationId)

    if (this.channel) {
      console.log("Unsubscribing from existing channel")
      this.channel.unsubscribe()
    }

    this.channel = consumer.subscriptions.create(
      {
        channel: "Turbo::StreamsChannel",
        signed_stream_name: signedStreamName
      },
      {
        connected() {
          console.log("Connected to channel for generation:", generationId)
        },
        disconnected() {
          console.log("Disconnected from channel")
        },
        received(data) {
          console.log("Received update:", data)
          Turbo.renderStreamMessage(data)
        },
        rejected() {
          console.log("Subscription was rejected")
        }
      }
    )
  }

  setLoading(isLoading) {
    this.generateButtonTarget.disabled = isLoading
    this.buttonTextTarget.classList.toggle('hidden', isLoading)
    this.loadingTextTarget.classList.toggle('hidden', !isLoading)
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