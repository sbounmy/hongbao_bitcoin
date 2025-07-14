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
      transitions from: :processing, to: :completed
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
end
