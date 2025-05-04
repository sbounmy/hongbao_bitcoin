class Paper < ApplicationRecord
  belongs_to :user, optional: true
  has_one_attached :image_front
  has_one_attached :image_back
  has_many :hong_baos, dependent: :nullify
  has_many :children, class_name: "Paper", foreign_key: :parent_id
  belongs_to :parent, class_name: "Paper", optional: true

  before_save :set_default_elements

  validates :name, presence: true
  validates :image_front, presence: true
  validates :image_back, presence: true
  validates :task_id, presence: false

  scope :active, -> { where(active: true).order(position: :asc) }
  scope :template, -> { where(public: true) }

  ELEMENTS = %w[
    app_public_address_qrcode
    private_key_qrcode
    private_key_text
    public_address_qrcode
    public_address_text
    mnemonic_text
    custom_text
  ].freeze

  ELEMENT_ATTRIBUTES = %i[x y size color max_text_width].freeze

  store :elements, accessors: ELEMENTS, prefix: true

  def self.ransackable_associations(auth_object = nil)
    [ "hong_baos", "user" ]
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "created_at", "id", "name", "updated_at", "public", "user_id" ]
  end

  def front_elements
    elements.slice("public_address_qrcode", "app_public_address_qrcode", "public_address_text")
  end

  def back_elements
    elements.slice("private_key_qrcode", "private_key_text", "mnemonic_text", "custom_text")
  end

  private

  def set_default_elements
    return if elements.present?

    self.elements = {
      "private_key_qrcode" => {
        "x" => 0.12,
        "y" => 0.38,
        "size" => 0.17,
        "color" => "224, 120, 1",
        "max_text_width" => 100
      },
      "private_key_text" => {
        "x" => 0.15,
        "y" => 0.35,
        "size" => 14,
        "color" => "224, 120, 1",
        "max_text_width" => 100
      },
      "public_address_qrcode" => {
        "x" => 0.55,
        "y" => 0.24,
        "size" => 0.25,
        "color" => "224, 120, 1",
        "max_text_width" => 100
      },
      "app_public_address_qrcode" => {
        "x" => 0.55,
        "y" => 0.24,
        "size" => 0.25,
        "color" => "224, 120, 1",
        "max_text_width" => 100
      },
      "public_address_text" => {
        "x" => 0.55,
        "y" => 0.24,
        "size" => 18,
        "color" => "0, 0, 0",
        "max_text_width" => 100
      },
      "mnemonic_text" => {
        "x" => 0.2,
        "y" => 0.2,
        "size" => 16,
        "color" => "0, 0, 0",
        "max_text_width" => 100
      },
      "custom_text" => {
        "x" => 0.2,
        "y" => 0.2,
        "size" => 16,
        "color" => "0, 0, 0",
        "max_text_width" => 100
      }
    }
  end
end
