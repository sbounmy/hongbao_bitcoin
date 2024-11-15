class HongBao < ApplicationRecord
  belongs_to :paper, optional: true

  validates :paper, presence: true, on: :create

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
