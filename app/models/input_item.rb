# Join table to connect Bundle and Inputs
class InputItem < ApplicationRecord
  belongs_to :input
  belongs_to :bundle
  has_one_attached :image # only for input type Image (User uploaded image)

  # Example : For Marvel, user can have to specify "Spiderman in purple"
  # In order to do that we need to let user input a prompt (stored in input_items) + input.promt which is the app's default prompt
  def prompt
    [ input.prompt, super ].compact_blank.join(". ")
  end
end
