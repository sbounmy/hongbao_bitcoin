class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  has_one :paper, dependent: :destroy
  validates :content, presence: true

  store :metadata, accessors: [ :costs, :tokens ]
  store :tokens, accessors: [ :input, :output, :input_text, :input_image, :total ], suffix: true
  store :costs, accessors: [ :input, :output, :total ], suffix: true
end
