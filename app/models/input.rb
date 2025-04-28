class Input < ApplicationRecord
  has_many :input_items, dependent: :destroy
  has_many :bundles, through: :input_items

  validates :name, presence: true

  has_one_attached :image

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "name", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "image_attachment" ]
  end
end
