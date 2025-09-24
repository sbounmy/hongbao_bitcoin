class OptionValue < ApplicationRecord
  belongs_to :option_type

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
    option_type.name == "color" && hex_color.present?
  end
end