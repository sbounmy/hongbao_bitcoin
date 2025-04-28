# Join table to connect Bundle and Inputs
class InputItem < ApplicationRecord
  belongs_to :input
  belongs_to :bundle
  has_one_attached :image # only for input type Image (User uploaded image)

  def prompt
    "#{input.prompt}. #{super} "
  end
end
