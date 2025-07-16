class Tag < ApplicationRecord
  include ArrayColumns
  include Metadata

  array_columns :tag_ids

  metadata :color, :icon

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug

  array_columns :categories

  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :for_category, ->(category) { with_any_categories(category) }

  # Helper methods for nested tags
  def tags
    @tags ||= Tag.where(id: tag_ids)
  end

  def tag_names
    tags.pluck(:name)
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end
end
