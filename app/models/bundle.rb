# Represents a collection of user-selected inputs (e.g., styles, themes)
# chosen for a specific generation task or request. It groups the associated
# `Input` records via the `InputItem` join table.
# Each input style with theme will be passed as a chat to the AI
class Bundle < ApplicationRecord
  belongs_to :user

  has_many :papers, dependent: :destroy
  has_many :input_items, dependent: :destroy
  has_many :inputs, through: :input_items, dependent: :destroy

  accepts_nested_attributes_for :input_items, allow_destroy: true

  validate :user_has_enough_tokens, on: :create
  has_many :styles, -> { where(inputs: { type: "Input::Style" }) }, through: :input_items, source: :input
  has_many :themes, -> { where(inputs: { type: "Input::Theme" }) }, through: :input_items, source: :input
  has_many :images, -> { where(inputs: { type: "Input::Image" }) }, through: :input_items, source: :input

  def theme
    themes.first
  end

  def image
    input_items.where(inputs: { type: "Input::Image" }).last&.image
  end

  private

  def user_has_enough_tokens
    if user&.tokens_sum < styles.count
      errors.add(:base, "Not enough tokens")
    end
  end
end
