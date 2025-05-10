class Input < ApplicationRecord
  has_many :input_items, dependent: :destroy
  has_many :bundles, through: :input_items

  validates :name, presence: true

  has_one_attached :image

  store :metadata
end
