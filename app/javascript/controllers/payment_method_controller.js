import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "paymentMethod",
    "mtPelerinData",
    "walletModal",
    "transferButtons",
    "confirmationButtons"
  ]

  connect() {
    // Initialize any necessary setup
  }

  methodSelected(event) {
    const methodName = event.target.dataset.methodName
    const mode = this.element.dataset.mode // 'deposit' or 'withdrawal'

    // Hide all wallet modals first
    this.walletModalTargets.forEach(modal => modal.classList.add('hidden'))

    if (methodName === 'mt_pelerin') {
      if (this.hasMtPelerinDataTarget) {
        const data = JSON.parse(this.mtPelerinDataTarget.dataset.options)
        if (mode === 'withdrawal') {
          this.showMtPelerinOfframp(data)
        } else {
          this.showMtPelerinOnramp(data)
        }
      }
    } else if (['bitstack', 'ledger'].includes(methodName)) {
      // Show the corresponding wallet modal
      const modal = this.walletModalTargets.find(m => m.dataset.walletType === methodName)
      if (modal) {
        modal.classList.remove('hidden')
      } else {
        console.error(`No modal found for wallet type: ${methodName}`)
      }
    }
  }

  showMtPelerinOnramp(data) {
    showMtpModal({
      _ctkn: data.ctkn,
      lang: data.locale,
      tab: 'buy',
      tabs: 'buy',
      net: data.network,
      nets: data.network,
      curs: 'EUR,USD,SGD',
      ctry: 'FR',
      primary: '#F04747',
      success: '#FFB636',
      amount: data.amount,
      mylogo: data.logo,
      addr: data.address,
      code: data.requestCode,
      hash: data.requestHash
    })
  }

  showMtPelerinOfframp(data) {
    showMtpModal({
      _ctkn: data.ctkn,
      lang: data.locale,
      tab: 'sell',
      tabs: 'sell',
      net: data.network,
      nets: data.network,
      curs: 'EUR,USD,SGD',
      ctry: 'FR',
      ssa: 0.001,
      primary: '#F04747',
      success: '#FFB636',
      amount: data.amount,
      mylogo: data.logo,
      addr: data.address,
      code: data.requestCode,
      hash: data.requestHash
    })
  }

  closeWalletModal(event) {
    event.preventDefault()
    this.walletModalTargets.forEach(modal => modal.classList.add('hidden'))
  }

  copyAddress(event) {
    event.preventDefault()
    const addressElement = this.element.querySelector('[data-payment-method-address]')
    if (addressElement) {
      navigator.clipboard.writeText(addressElement.dataset.paymentMethodAddress)
    }
  }

  showConfirmation(event) {
    event.preventDefault()
    this.transferButtonsTarget.classList.add('hidden')
    this.confirmationButtonsTarget.classList.remove('hidden')
  }

  cancelTransfer(event) {
    event.preventDefault()
    this.confirmationButtonsTarget.classList.add('hidden')
    this.transferButtonsTarget.classList.remove('hidden')
  }

  confirmTransfer(event) {
    // The form will submit naturally
    // You can add additional validation here if needed
  }

  async openQrScanner(event) {
    event.preventDefault()

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })

      // Create QR scanner modal
      const modal = document.createElement('div')
      modal.className = "fixed inset-0 bg-black/90 flex items-center justify-center p-4 z-50"
      modal.innerHTML = `
        <div class="relative w-full max-w-md">
          <button class="absolute top-2 right-2 text-white/60 hover:text-white z-10"
                  data-action="click->payment-method#closeQrScanner">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none"
                 viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
          <video class="w-full rounded-lg"></video>
        </div>
      `

      document.body.appendChild(modal)

      const video = modal.querySelector('video')
      video.srcObject = stream
      video.play()

      // Initialize QR code scanner
      const qrScanner = new QrScanner(video, result => {
        this.handleQrResult(result)
        this.closeQrScanner()
      })

      qrScanner.start()
      this.qrScanner = qrScanner
    } catch (error) {
      console.error('Failed to open camera:', error)
      // Show error message to user
    }
  }

  closeQrScanner() {
    if (this.qrScanner) {
      this.qrScanner.stop()
      this.qrScanner.destroy()
      this.qrScanner = null
    }

    const modal = document.querySelector('[data-payment-method-scanner]')
    if (modal) {
      modal.remove()
    }
  }

  handleQrResult(result) {
    const addressInput = this.element.querySelector('input[name="hong_bao[to_address]"]')
    if (addressInput) {
      addressInput.value = result
    }
  }
}