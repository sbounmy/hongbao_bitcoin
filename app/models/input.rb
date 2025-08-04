class Input < ApplicationRecord
  include Positionable
  include ArrayColumns
  include Metadata
  extend FriendlyId

  friendly_id :name, use: :slugged
  array_columns :tag_ids

  has_many :input_items, dependent: :destroy
  has_many :bundles, through: :input_items

  validates :name, presence: true

  has_one_attached :image


  # Whether the input can be rendered as a view
  # e.g inputs/events/show, inputs/themes/show
  class_attribute :renderable, default: false

  # Helper methods for tags
  def tags
    @tags ||= Tag.where(id: tag_ids)
  end

  def tag_names
    tags.pluck(:name)
  end
end
