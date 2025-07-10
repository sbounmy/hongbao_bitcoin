class Order < ApplicationRecord
  belongs_to :user
  has_many :line_items, dependent: :destroy
  has_many :tokens, dependent: :destroy

  enum status: {
    pending: "pending",
    completed: "completed",
    failed: "failed"
  }

  enum payment_provider: {
    stripe: "stripe",
    btcpay: "btcpay"
  }

  # external_id is the unique identifier for the transaction in the payment gateway
  validates :external_id, presence: true, uniqueness: true
end
