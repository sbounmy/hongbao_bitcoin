class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  validates :content, presence: true

  store :tokens, accessors: [ :input, :output, :input_text, :input_image, :total ], suffix: true
end
