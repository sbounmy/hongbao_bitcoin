module Ai
  class Message < ApplicationRecord
    has_one_attached :preview_image
    validates :title, :text, presence: true
  end
end
