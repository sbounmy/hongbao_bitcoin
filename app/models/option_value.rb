class OptionValue < ApplicationRecord
  include Metadata

  belongs_to :option_type

  metadata :color

  validates :name, presence: true, uniqueness: { scope: :option_type_id }
  validates :presentation, presence: true

  scope :ordered, -> { order(:position) }
  scope :for_option_type, ->(type_name) { joins(:option_type).where(option_types: { name: type_name }) }

  def self.find_by_name_and_type(name, type_name)
    joins(:option_type)
      .where(name: name.to_s.downcase)
      .where(option_types: { name: type_name.to_s.downcase })
      .first
  end

  def color?
    option_type.name == "color" && color.present?
  end

  def move_higher
    return if position <= 0
    transaction do
      sibling = self.class.where(option_type_id: option_type_id)
                          .where("position < ?", position)
                          .order(position: :desc).first
      return unless sibling
      sibling.update!(position: position)
      update!(position: position - 1)
    end
  end

  def move_lower
    transaction do
      sibling = self.class.where(option_type_id: option_type_id)
                          .where("position > ?", position)
                          .order(position: :asc).first
      return unless sibling
      sibling.update!(position: position)
      update!(position: position + 1)
    end
  end
end
