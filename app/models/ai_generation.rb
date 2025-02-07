class AiGeneration < ApplicationRecord
  validates :prompt, presence: true
  validates :generation_id, presence: true, uniqueness: true
  validates :status, presence: true

  attribute :image_urls, :json, default: []
end
