class PaymentMethod < ApplicationRecord
  include Positionable
  has_many :hong_baos
  has_one_attached :logo

  validates :name, presence: true, uniqueness: true
  validates :instructions, presence: true

  # Scope for active payment methods
  scope :active, -> { where(active: true) }
end
