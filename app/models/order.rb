class Order < ApplicationRecord
  include AASM

  aasm column: "state" do
    state :pending, initial: true
    state :processing
    state :completed
    state :failed

    event :process do
      transitions from: :pending, to: :processing
    end

    event :complete do
      transitions from: [ :pending, :processing ], to: :completed
    end

    event :fail do
      transitions from: [ :pending, :processing ], to: :failed
    end
  end

  belongs_to :user, optional: true
  has_many :line_items, dependent: :destroy
  has_many :tokens, dependent: :destroy

  enum :payment_provider, {
    stripe: "stripe",
    btcpay: "btcpay"
  }

  # external_id is the unique identifier for the transaction in the payment gateway
  validates :external_id, presence: true, uniqueness: true

  def payment_provider_dashboard_url
    case payment_provider
    when "stripe"
      stripe_dashboard_url
    when "btcpay"
      btcpay_dashboard_url
    end
  end

  def formatted_total
    "#{currency.upcase} #{total_amount}"
  end

  private

  def stripe_dashboard_url
    # Stripe stores payment intent IDs in external_id
    "https://dashboard.stripe.com/payments/#{external_id}"
  end

  def btcpay_dashboard_url
    # BTCPay stores payment request IDs in external_id
    return unless ENV["BTCPAY_HOST"].present?

    "https://#{ENV["BTCPAY_HOST"]}/payment-requests/#{external_id}"
  end
end
