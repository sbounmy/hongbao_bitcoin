class OptionType < ApplicationRecord
  has_many :option_values, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :presentation, presence: true

  scope :ordered, -> { order(:position) }

  def self.find_by_name(name)
    find_by(name: name.to_s.downcase)
  end
end