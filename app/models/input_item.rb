class InputItem < ApplicationRecord
  belongs_to :input
  belongs_to :bundle
  has_one_attached :image
end
