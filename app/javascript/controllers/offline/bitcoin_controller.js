import { Controller } from "@hotwired/stimulus"
import WalletFactory from "../../services/bitcoin/wallet_factory"
import CustomWallet from "../../services/bitcoin/custom_wallet"
import Transaction from "../../services/bitcoin/transaction"
import TransactionFactory from "../../services/bitcoin/transaction_factory"

export default class extends Controller {
  static values = {
    autoGenerate: { type: Boolean, default: false },
    customWallet: { type: Boolean, default: false },
    network: { type: String, default: 'mainnet' },
    mode: { type: String, default: 'beginner' },
    hongbaoLogo: String,
    bitcoinLogo: String
  }
  static targets = ["utxos"]

  connect() {
    // BitcoinWallet.setNetwork(this.networkValue)
    if (this.autoGenerateValue) {
      this.generate()
    }
  }

  generate() {
    this.master = WalletFactory.createDefault({ network: this.networkValue })
    this.wallet = this.master.derive('0')
    this.customWalletValue = false
    this.dispatchWalletChanged()
  }

  new(privateKey, mnemonic) {
    const options = {
      privateKey,
      mnemonic,
      network: this.networkValue
    }

    this.wallet = WalletFactory.createDefault(options)
    this.dispatchWalletChanged()
  }

  generateNewKeys() {
    this.generate()
  }

  useCustomKeys() {
    this.master = new CustomWallet({ network: this.networkValue });
    this.master.mnemonic = ''
    this.wallet = this.master.derive('0')
    this.customWalletValue = true
    this.dispatchWalletChanged()
  }

  dispatchWalletChanged() {
    this.dispatch("changed", {
      detail: this.detail
    })
  }

  get detail() {
    const walletInfo = this.wallet.info;

    // Choose which QRCODE to use based on the current mode.
    const activeQrCodeFunction = this.modeValue === 'beginner'
      ? walletInfo.appPublicAddressQrcode
      : walletInfo.publicAddressQrcode;

    // Choose logo based on mode
    const logoUrl = this.modeValue === 'beginner'
      ? this.hongbaoLogoValue
      : this.bitcoinLogoValue;

    return {
      wallet: this.wallet,
      mnemonicText: this.master?.mnemonic || '',
      // Pass all original info from the wallet, including appPublicAddressQrcode.
      ...walletInfo,
      // we have to override QR code functions to include logo
      publicAddressQrcode: async () => await activeQrCodeFunction(logoUrl),
      privateKeyQrcode: walletInfo.privateKeyQrcode  // No logo for private key
    };
  }

  async transfer(address, fee) {
    try {
      const transaction = TransactionFactory.create(
        this.wallet.privateKey,
        address,
        fee,
        this.utxos,
        this.networkValue
      )
      await transaction.build()
      const result = await transaction.broadcast()

      console.log("transferSuccess", result)
      this.dispatch("transferSuccess", {
        detail: {
          txid: result.txid,
          hex: result.hex,
          url: transaction.explorerUrl
        }
      })
    } catch (error) {
      alert(error.message)
      console.error("Error transferring transaction", error)
      this.dispatch("transferError", { detail: error.message })
    }
  }

  get utxos() {
    return JSON.parse(this.utxosTarget.textContent)
  }

  // Public API methods that other controllers can use
  sign(message) {
    return this.wallet.sign(message)
  }

  verify(message, signature, address) {
    return this.wallet.verify(message, signature, address)
  }

  publicAddressChanged(event) {
    this.#walletPropertyChange('publicAddress', event.target.value);
  }

  privateKeyChanged(event) {
    this.#walletPropertyChange('privateKey', event.target.value);
  }

  mnemonicChanged(event) {
    this.#walletPropertyChange('mnemonic', event.target.value);
  }

  modeChanged(event) {
    if (event.target.value == 'custom') {
      this.customWalletValue = true;
    }
    // Update the internal state based on the radio button value.
    this.modeValue = event.target.value;

    // Dispatch the 'changed' event. The canva_controller will listen for this
    //    and redraw everything using the new data from the `detail` getter.
    this.dispatchWalletChanged();
  }

  customWalletChanged(event) {
    // dirty hack to get the property name from the data-binding-name-value
    // mnemonicText -> mnemonic
    // privateKeyText -> privateKey
    // publicAddressText -> publicAddress
    const propertyName = event.detail.source.dataset.bindingNameValue.replace('Text', '')
    this.#walletPropertyChange(propertyName, event.detail.key);
  }
  // Private methods
  #walletPropertyChange(propertyName, value) {
    const walletOptions = { network: this.networkValue };
    walletOptions[propertyName] = value;

    if (!(this.master instanceof CustomWallet)) {
      this.master = new CustomWallet(walletOptions);
    }
    this.master[propertyName] = value;
    this.customWalletValue = true;
    this.wallet = this.master.derive('0');
    this.dispatchWalletChanged();
  }
}