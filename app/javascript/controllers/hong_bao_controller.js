import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amount", "feeCalculation"]

  calculateFees() {
    const amount = parseFloat(this.amountTarget.value) || 0
    const platformFee = amount * 0.03
    const gasFee = 5
    const totalCost = amount + platformFee + gasFee
    const btcAmount = amount / 30000

    if (amount > 0) {
      this.feeCalculationTarget.innerHTML = this.feeTemplate(amount, platformFee, gasFee, totalCost, btcAmount)
      this.feeCalculationTarget.classList.remove('hidden')
    } else {
      this.feeCalculationTarget.classList.add('hidden')
    }
  }

  feeTemplate(amount, platformFee, gasFee, totalCost, btcAmount) {
    return `
      <div class="space-y-2">
        <div class="flex justify-between">
          <span>${I18n.t('hong_baos.new.estimated_btc')}:</span>
          <span>${btcAmount.toFixed(8)} BTC</span>
        </div>
        <div class="flex justify-between">
          <span>${I18n.t('hong_baos.new.platform_fee')} (3%):</span>
          <span>$${platformFee.toFixed(2)}</span>
        </div>
        <div class="flex justify-between">
          <span>${I18n.t('hong_baos.new.gas_fee')}:</span>
          <span>$${gasFee.toFixed(2)}</span>
        </div>
        <div class="flex justify-between font-bold">
          <span>${I18n.t('hong_baos.new.total_cost')}:</span>
          <span>$${totalCost.toFixed(2)}</span>
        </div>
      </div>
    `
  }
} 