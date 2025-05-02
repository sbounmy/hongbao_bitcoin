class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  validates :content, presence: true

  store :metadata, accessors: [ :costs, :tokens ]
  store :tokens, accessors: [ :input, :output, :input_text, :input_image, :total ], suffix: true
  store :costs, accessors: [ :input, :output, :total ], suffix: true

  def self.ransackable_attributes(auth_object = nil)
    %w[id content user_id chat_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
