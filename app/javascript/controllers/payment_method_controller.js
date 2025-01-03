import { Controller } from "@hotwired/stimulus"
import BitcoinWallet from "services/bitcoin_wallet"

export default class extends Controller {
  static targets = ["paymentMethod"]

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

  openWalletModal(methodName) {
    const modal = document.querySelector(`[data-wallet-modal="${methodName}"]`)
    if (modal) {
      modal.showModal()
    }
  }
}