module Ai
  class Generation < ApplicationRecord
    belongs_to :user
    validates :prompt, presence: true
    validates :generation_id, presence: true, uniqueness: true
    validates :status, presence: true

    attribute :image_urls, :json, default: []
    has_one_attached :face_to_swap, dependent: :destroy
  end
end
