class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :bundle
  has_many :messages, dependent: :destroy
end
