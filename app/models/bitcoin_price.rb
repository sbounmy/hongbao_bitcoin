class BitcoinPrice < ApplicationRecord
  validates :date, presence: true, uniqueness: { scope: :currency }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR] }
end
