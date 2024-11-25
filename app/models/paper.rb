class Paper < ApplicationRecord
  has_one_attached :image_front
  has_one_attached :image_back
  has_many :hong_baos

  validates :name, presence: true
  validates :image_front, presence: true
  validates :image_back, presence: true
  validates :style, presence: true

  enum :style, {
    classic: 0,
    modern: 1,
    lunar: 2
  }

  scope :active, -> { where(active: true).order(position: :asc) }

  ELEMENTS = [
    :qrcode_private_key,
    :qrcode_private_key_label,
    :qrcode_public_key,
    :qrcode_public_key_label,
    :private_key_address,
    :private_key_address_label,
    :public_key_address,
    :public_key_address_label,
    :amount,
    :amount_btc
  ]

  store :elements, accessors: ELEMENTS, prefix: true
end
