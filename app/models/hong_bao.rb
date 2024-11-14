class HongBao < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than: 0, less_than: 1000 }

  before_create :generate_private_key

  BTC_PRICE = 30_000 # Simulated BTC price in USD
  GAS_FEE = 5 # Fixed gas fee in USD
  PLATFORM_FEE_PERCENTAGE = 0.03

  enum :status, { pending: 0, paid: 1, printed: 2 }

  def amount=(value)
    super(value)
    self.platform_fee = amount * PLATFORM_FEE_PERCENTAGE
    self.gas_fee = GAS_FEE
    self.total_cost = amount + platform_fee + gas_fee
    self.btc_amount = amount / BTC_PRICE
  end

  def total_amount_cents
    (total_cost * 100).to_i
  end

  private


  def generate_private_key
    self.private_key = "L" + SecureRandom.alphanumeric(50)
  end
end
