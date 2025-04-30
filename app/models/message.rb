class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  validates :content, presence: true
end
