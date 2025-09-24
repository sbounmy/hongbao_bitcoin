class OptionType < ApplicationRecord
  has_many :option_values, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :presentation, presence: true

  scope :ordered, -> { order(:position) }

  def self.find_by_name(name)
    find_by(name: name.to_s.downcase)
  end

  def move_higher
    return if position <= 0
    transaction do
      sibling = self.class.where("position < ?", position).order(position: :desc).first
      return unless sibling
      sibling.update!(position: position)
      update!(position: position - 1)
    end
  end

  def move_lower
    transaction do
      sibling = self.class.where("position > ?", position).order(position: :asc).first
      return unless sibling
      sibling.update!(position: position)
      update!(position: position + 1)
    end
  end
end