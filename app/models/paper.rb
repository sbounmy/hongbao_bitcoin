class Paper < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :bundle, optional: true
  has_one_attached :image_front
  has_one_attached :image_back
  has_many :hong_baos, dependent: :nullify
  has_many :children, class_name: "Paper", foreign_key: :parent_id
  belongs_to :parent, class_name: "Paper", optional: true

  before_validation :set_default_elements

  validates :name, presence: true
  validates :image_front, presence: true
  validates :image_back, presence: true
  validates :task_id, presence: false
  validates :elements, presence: true

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

  def input_items
    bundle.input_items.where(id: input_item_ids)
  end

  def input_items=(input_items)
    self.input_item_ids = input_items.map(&:id)
  end

  def inputs
    input_items.map(&:input)
  end

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
    self.elements = bundle&.theme&.ai || Input::Theme.default_ai_elements
  end
end
