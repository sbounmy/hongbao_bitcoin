import { Controller } from "@hotwired/stimulus"
import WalletFactory from "services/bitcoin/wallet_factory"
import CustomWallet from "services/bitcoin/custom_wallet"
import Transaction from "services/bitcoin/transaction"
import TransactionFactory from "services/bitcoin/transaction_factory"

export default class extends Controller {
  static values = {
    network: { type: String, default: 'mainnet' },
    autoGenerate: { type: Boolean, default: false },
    utxos: { type: String, default: '' }
  }

  connect() {
    // BitcoinWallet.setNetwork(this.networkValue)
    if (this.autoGenerateValue) {
      this.generate()
    }
  }

  generate() {
    this.master = WalletFactory.createDefault({ network: this.networkValue })
    this.wallet = this.master.derive('0')
    this.#dispatchWalletChanged()
  }

  new(privateKey, mnemonic) {
    const options = {
      privateKey,
      mnemonic,
      network: this.networkValue
    }

    console.log(options)
    this.wallet = WalletFactory.createDefault(options)
    this.#dispatchWalletChanged()
  }

  get detail() {
    return {
      wallet: this.wallet,
      mnemonicText: this.master?.mnemonic || '',
      ...this.wallet.info
    }
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
      console.log(transaction)
      const result = await transaction.broadcast()

      this.dispatch("transfer:success", {
        detail: {
          txid: result.txid,
          hex: result.hex,
          url: transaction.explorerUrl
        }
      })
    } catch (error) {
      console.error("Error transferring transaction", error)
      this.dispatch("transfer:error", { detail: error.message })
    }
  }

  get utxos() {
    return JSON.parse(this.utxosValue)
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

  // Private methods
  #walletPropertyChange(propertyName, value) {
    const walletOptions = { network: this.networkValue };
    walletOptions[propertyName] = value;

    if (this.master instanceof CustomWallet) {
      this.master[propertyName] = value;
    } else {
      this.master = new CustomWallet(walletOptions);
    }
    this.wallet = this.master.derive('0');
    this.#dispatchWalletChanged();
  }

  #dispatchWalletChanged() {
    this.dispatch("changed", {
      detail: this.detail
    })
  }
}