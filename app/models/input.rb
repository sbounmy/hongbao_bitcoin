class Input < ApplicationRecord
  include Positionable

  has_many :input_items, dependent: :destroy
  has_many :bundles, through: :input_items

  validates :name, presence: true

  has_one_attached :image

  store :metadata


  # Whether the input can be rendered as a view
  # e.g inputs/events/show, inputs/themes/show
  class_attribute :renderable, default: false
end
