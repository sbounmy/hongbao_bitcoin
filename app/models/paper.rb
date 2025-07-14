class Paper < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :bundle, optional: true
  belongs_to :message, optional: true
  has_one_attached :image_front
  has_one_attached :image_back
  has_one_attached :image_full
  has_many :children, class_name: "Paper", foreign_key: :parent_id
  belongs_to :parent, class_name: "Paper", optional: true

  before_validation :set_default_elements
  after_create_commit :broadcast_prepend
  after_update_commit :broadcast_replace

  validates :name, presence: true
  validates :elements, presence: true

  scope :active, -> { where(active: true) }
  scope :template, -> { where(public: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :events, -> { joins(:input_items).where(input_items: { input_type: "Input::Event" }) }

  include ArrayColumns
  array_columns :input_ids, :input_item_ids

  ELEMENTS = %w[
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
    bundle&.input_items&.where(id: input_item_ids) || []
  end

  def input_items=(input_items)
    self.input_item_ids = input_items.map(&:id)
    self.input_ids = input_items.map(&:input_id)
  end

  def inputs
    Input.where(id: input_ids)
  end

  def theme
    input_items.find { |item| item.input.is_a?(Input::Theme) }
  end

  def style
    input_items.find { |item| item.input.is_a?(Input::Style) }
  end

  def event
    input_items.find { |item| item.input.is_a?(Input::Event) }
  end

  def front_elements
    elements.slice("public_address_qrcode", "public_address_text")
  end

  def back_elements
    elements.slice("private_key_qrcode", "private_key_text", "mnemonic_text", "custom_text")
  end

  private

  def broadcast_prepend
    broadcast_prepend_to :papers, renderable: Papers::ItemComponent.new(item: self, broadcast: true)
  end

  def broadcast_replace
    broadcast_replace_to self, renderable: Papers::ItemComponent.new(item: self, broadcast: false)
  end

  def set_default_elements
    return if elements.present?
    self.elements = bundle&.theme&.ai || Input::Theme.default_ai_elements
  end
end
