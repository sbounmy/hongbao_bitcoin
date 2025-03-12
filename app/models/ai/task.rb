module Ai
  class Task < ApplicationRecord
    belongs_to :user
    validates :status, presence: true
    has_many_attached :images, dependent: :destroy
  end
end
