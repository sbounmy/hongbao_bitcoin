class Paper < ApplicationRecord
  belongs_to :user
  has_one_attached :image_front
  has_one_attached :image_back
  has_many :hong_baos, dependent: :nullify

  validates :name, presence: true
  validates :image_front, presence: true
  validates :image_back, presence: true
  validates :style, presence: true
  validates :user, presence: true

  enum :style, {
    classic: 0,
    modern: 1,
    lunar: 2
  }

  scope :active, -> { where(active: true).order(position: :asc) }
  scope :public_papers, -> { where(public: true) }

  ELEMENTS = %w[
    qrcode_private_key
    private_key
    qrcode_public_key
    public_address
    custom_text
  ].freeze

  ELEMENT_ATTRIBUTES = %i[x y size color].freeze

  store :elements, accessors: ELEMENTS, prefix: true

  def self.ransackable_associations(auth_object = nil)
    [ "hong_baos", "user" ]
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "created_at", "id", "name", "updated_at", "public", "user_id" ]
  end
end
