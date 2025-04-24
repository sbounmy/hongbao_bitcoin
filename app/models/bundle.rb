class Bundle < ApplicationRecord
  belongs_to :user

  has_many :input_items, dependent: :destroy
  has_many :inputs, through: :input_items, dependent: :destroy

  accepts_nested_attributes_for :input_items, allow_destroy: true
end
