class Paper < ApplicationRecord
  has_many_attached :images
  has_many :hong_baos

  validates :name, presence: true
  validates :images, presence: true
  validates :style, presence: true

  enum :style, {
    classic: 0,
    modern: 1,
    lunar: 2
  }

  scope :active, -> { where(active: true).order(position: :asc) }
end
