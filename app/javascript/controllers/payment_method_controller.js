import { Controller } from "@hotwired/stimulus"
import BitcoinWallet from "services/bitcoin_wallet"

export default class extends Controller {
  static targets = ["paymentMethod", "addressDisplay", "addressData"]

  connect() {
    this.address = ""
  }

  updateAddress(event) {
    const { address } = event.detail
    this.address = address
    this.addressDataTarget.textContent = address

    // Update the displayed address component
    this.addressDisplayTarget.innerHTML = this.buildAddressDisplay(address)
  }

  async methodSelected(event) {
    const method = event.target
    const methodName = method.dataset.methodName

    if (methodName === "mt_pelerin") {
      const wallet = new BitcoinWallet('testnet') // or get from config
      const mtPelerinData = await wallet.generateMtPelerinRequest()

      // Launch Mt Pelerin with generated data
      this.launchMtPelerin({
        token: method.dataset.mtPelerinToken,
        rfr: method.dataset.mtPelerinRfr,
        address: this.address,
        ...mtPelerinData
      })
    } else {
      // Handle other payment methods
      this.openWalletModal(methodName)
    }
  }

  launchMtPelerin(options) {
    const mtPelerinUrl = new URL("https://buy.mtpelerin.com/")
    mtPelerinUrl.searchParams.set("ctkn", options.token)
    mtPelerinUrl.searchParams.set("locale", document.documentElement.lang)
    mtPelerinUrl.searchParams.set("network", "bitcoin_testnet") // or from config
    mtPelerinUrl.searchParams.set("rfr", options.rfr)
    mtPelerinUrl.searchParams.set("address", options.address)
    mtPelerinUrl.searchParams.set("requestCode", options.requestCode)
    mtPelerinUrl.searchParams.set("requestHash", options.requestHash)

    window.open(mtPelerinUrl.toString(), "_blank")
  }

  buildAddressDisplay(address) {
    return `
      <div class="relative bg-white/10 rounded-lg p-4">
        <div class="flex items-center justify-between gap-4">
          <div class="flex-1">
            <div class="font-mono text-sm break-all text-white/90">${address}</div>
          </div>
          <div data-controller="clipboard" data-clipboard-success-message-value="Address copied!">
            <input type="text" class="sr-only" value="${address}" data-clipboard-target="source">
            <button data-action="clipboard#copy"
                    class="text-[#FFB636] p-1.5 hover:text-[#FFB636]/80 transition-colors">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                   stroke="currentColor" class="w-5 h-5">
                <path stroke-linecap="round" stroke-linejoin="round"
                      d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    `
  }

  openWalletModal(methodName) {
    const modal = document.querySelector(`[data-wallet-modal="${methodName}"]`)
    if (modal) {
      modal.showModal()
    }
  }
}