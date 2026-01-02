class PaymentMethod < ApplicationRecord
  include Activable
  include Positionable

  has_many :hong_baos
  has_one_attached :logo

  validates :name, presence: true, uniqueness: true
  validates :instructions, presence: true
end
