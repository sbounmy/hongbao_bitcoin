class Paper < ApplicationRecord
  include Likeable
  include Viewable
  include ArrayColumns
  include Metadata
  include Taggable

  belongs_to :user, optional: true
  belongs_to :bundle, optional: true
  has_one_attached :image_front
  has_one_attached :image_back
  has_one_attached :image_full
  has_one_attached :image_portrait

  before_validation :set_default_elements
  after_create_commit :broadcast_prepend
  after_update_commit :broadcast_replace

  validates :name, presence: true
  validates :elements, presence: true

  scope :active, -> { where(active: true) }
  scope :template, -> { where(public: true) }
  scope :recent, -> { order(created_at: :desc) }

  scope :with_input, ->(input) { with_any_input_ids(input.id) }
  scope :with_input_type, ->(type) { with_any_input_ids(Input.where(type: type).pluck(:id)) }
  scope :with_themes, -> { with_input_type("Input::Theme") }
  scope :with_events, -> { with_input_type("Input::Event") }
  scope :with_styles, -> { with_input_type("Input::Style") }

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

  # Elements are stored in elements column, not metadata
  store :elements, accessors: ELEMENTS, prefix: true

  # Metadata fields
  metadata :prompt
  metadata :costs, accessors: [ :input, :output, :total ], suffix: true
  metadata :tokens, accessors: [ :input, :output, :input_text, :input_image, :total ], suffix: true

  def input_items
    InputItem.where(id: input_item_ids)
  end

  def input_items=(input_items)
    self.input_item_ids = input_items.map(&:id)
    self.input_ids = input_items.map(&:input_id)
  end

  def inputs
    Input.where(id: input_ids)
  end

  def theme
    inputs.find { |i| i.is_a?(Input::Theme) }
  end

  def style
    inputs.find { |i| i.is_a?(Input::Style) }
  end

  def event
    inputs.find { |i| i.is_a?(Input::Event) }
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
