# Represents a collection of user-selected inputs (e.g., styles, themes)
# chosen for a specific generation task or request. It groups the associated
# `Input` records via the `InputItem` join table.
# Each input style with theme will be passed as a chat to the AI
class Bundle < ApplicationRecord
  belongs_to :user

  has_many :input_items, dependent: :destroy
  has_many :inputs, through: :input_items, dependent: :destroy

  accepts_nested_attributes_for :input_items, allow_destroy: true
end
