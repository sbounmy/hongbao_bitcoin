class Paper < ApplicationRecord
  has_one_attached :image
  has_many :hong_baos

  validates :name, presence: true
  validates :image, presence: true
  validates :style, presence: true

  enum :style, {
    classic: 0,
    modern: 1,
    lunar: 2
  }

  scope :active, -> { where(active: true).order(position: :asc) }
end
