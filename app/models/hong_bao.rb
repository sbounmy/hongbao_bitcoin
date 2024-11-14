class HongBao < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than: 0 }

  before_save :calculate_fees
  before_create :generate_private_key

  BTC_PRICE = 30_000 # Simulated BTC price in USD
  GAS_FEE = 5 # Fixed gas fee in USD
  PLATFORM_FEE_PERCENTAGE = 0.03

  private

  def calculate_fees
    self.platform_fee = amount * PLATFORM_FEE_PERCENTAGE
    self.gas_fee = GAS_FEE
    self.total_cost = amount + platform_fee + gas_fee
    self.btc_amount = amount / BTC_PRICE
  end

  def generate_private_key
    self.private_key = "L" + SecureRandom.alphanumeric(50)
  end
end
