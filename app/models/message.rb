class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  validates :content, presence: true

  store :metadata, accessors: [ :cost, :tokens ]

  store :tokens, accessors: [ :input, :output, :input_text, :input_image, :total ], suffix: true

  store :cost, accessors: [ :input, :output, :total ], suffix: true
end
