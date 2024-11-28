class PaymentMethod < ApplicationRecord
  has_many :hong_baos
  has_one_attached :logo

  validates :name, presence: true, uniqueness: true
  validates :instructions, presence: true

  # Predefined payment methods
  METHODS = %w[mt_pelerin bitstack ledger].freeze
  validates :name, inclusion: { in: METHODS }

  # Scope for active payment methods
  scope :active, -> { where(active: true) }
end
