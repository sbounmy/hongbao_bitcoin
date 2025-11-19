class Input::Theme < Input
  POSITION = 1

  self.renderable = true

  CSS_PROPERTIES = [
    "color-base-100",       # Base color of page, used for blank backgrounds
    "color-base-200",       # Base color, darker shade
    "color-base-300",       # Base color, even more darker shade
    "color-base-content",   # Foreground content color to use on base color
    "color-primary",        # Primary brand color
    "color-primary-content", # Foreground content color to use on primary color
    "color-secondary",      # Secondary brand color
    "color-secondary-content", # Foreground content color to use on secondary color
    "color-accent",         # Accent brand color
    "color-accent-content", # Foreground content color to use on accent color
    "color-neutral",        # Neutral dark color
    "color-neutral-content", # Foreground content color to use on neutral color
    "color-info",           # Info color
    "color-info-content",   # Foreground content color to use on info color
    "color-success",        # Success color
    "color-success-content", # Foreground content color to use on success color
    "color-warning",        # Warning color
    "color-warning-content", # Foreground content color to use on warning color
    "color-error",          # Error color
    "color-error-content",  # Foreground content color to use on error color
    "radius-selector",      # Border radius for selectors like checkbox, toggle, badge, etc
    "radius-field",         # Border radius for fields like input, select, tab, etc
    "radius-box",           # Border radius for boxes like card, modal, alert, etc
    "size-selector",        # Base scale size for selectors like checkbox, toggle, badge, etc
    "size-field",           # Base scale size for fields like input, select, tab, etc
    "border",               # Border width of all components
    "depth",                # (binary) Adds a depth effect for relevant components
    "noise"                 # (binary) Adds a background noise effect for relevant components
  ]
  UI_PROPERTIES = CSS_PROPERTIES.map(&:underscore)

  AI_ELEMENT_TYPES = [
    "private_key_qrcode",
    "private_key_text",
    "public_address_qrcode",
    "public_address_text",
    "mnemonic_text",
    "portrait"
  ].freeze

  AI_ELEMENT_PROPERTIES = [
    "x",
    "y",
    "width",
    "height",
    "size",
    "color",
    "opacity",
    "resolution",
  ].freeze

  # Element type definitions for visual editor
  ELEMENT_TYPES = {
    "shape" => {
      properties: ["x", "y", "width", "height", "color", "opacity"],
      uses_size: false
    },
    "text" => {
      properties: ["x", "y", "width", "height", "size", "color", "opacity"],
      uses_size: true
    }
  }.freeze

  # Aspect ratio configuration per element type
  # nil = no aspect ratio constraint
  # Float = fixed ratio (1.0 for square)
  # :shift_key = user holds Shift to lock ratio
  ELEMENT_ASPECT_RATIOS = {
    "private_key_qrcode" => 1.0,      # Always square
    "public_address_qrcode" => 1.0,   # Always square
    "portrait" => :shift_key,         # Shift to lock
    "private_key_text" => nil,
    "public_address_text" => nil,
    "mnemonic_text" => nil
  }.freeze

  # Map elements to their types
  ELEMENT_TYPE_MAP = {
    "private_key_qrcode" => "shape",
    "public_address_qrcode" => "shape",
    "portrait" => "shape",
    "private_key_text" => "text",
    "public_address_text" => "text",
    "mnemonic_text" => "text"
  }.freeze

  AI_PROPERTIES = AI_ELEMENT_TYPES.index_with { |_type| AI_ELEMENT_PROPERTIES }.freeze

  def self.default_ai_elements
    {
      "private_key_qrcode" => {
        "x" => 12,
        "y" => 38,
        "width" => 17,
        "height" => 17,
        "color" => "224, 120, 1",
        "opacity" => 1.0
      },
      "private_key_text" => {
        "x" => 15,
        "y" => 35,
        "width" => 12,
        "height" => 10,
        "size" => 1.8,
        "color" => "224, 120, 1",
        "opacity" => 1.0
      },
      "public_address_qrcode" => {
        "x" => 55,
        "y" => 24,
        "width" => 25,
        "height" => 25,
        "color" => "224, 120, 1",
        "opacity" => 1.0,
        "hidden" => true
      },
      "public_address_text" => {
        "x" => 55,
        "y" => 24,
        "width" => 12,
        "height" => 10,
        "size" => 1.8,
        "color" => "0, 0, 0",
        "opacity" => 1.0
      },
      "mnemonic_text" => {
        "x" => 20,
        "y" => 20,
        "width" => 12,
        "height" => 15,
        "size" => 1.6,
        "color" => "0, 0, 0",
        "opacity" => 1.0
      },
      "portrait" => {
        "x" => 34,              # percentage from left
        "y" => 8,               # percentage from top
        "width" => 18,          # percentage of template width
        "height" => 23,         # percentage of template height
        "color" => "",          # Tone color (hex) - empty means no tint
        "opacity" => 0.25,      # Tone opacity (0.0 - 1.0)
        "resolution" => "1024x1024",  # AI generation size: 1024x1024, 1536x1024, 1024x1536
      }
    }
  end

  has_one_attached :image_hero
  has_one_attached :image_back
  has_one_attached :image_front

  validates :ui_name, presence: true
  validates :slug, presence: true, uniqueness: true

  metadata :ui, accessors: [ :name ] + UI_PROPERTIES, prefix: true
  metadata :ai, accessors: [ :name ] + AI_ELEMENT_TYPES, prefix: true
  metadata :spotify, accessors: [ :path ], prefix: true

  AI_ELEMENT_TYPES.each do |type|
    store :"ai_#{type}", accessors: AI_ELEMENT_PROPERTIES, prefix: true
  end


  before_save :delete_empty_ui_properties

  def ui_name
   super || "cyberpunk"
  end

  # We cannot set null / empty for color picker so when its default value we remove it
  # https://github.com/whatwg/html/issues/9572
  def delete_empty_ui_properties
    ui.delete_if { |key, value| value.blank? || value == "#000000" }
  end

  # Helper method to get portrait configuration with defaults
  def portrait_config
    ai["portrait"] || self.class.default_ai_elements["portrait"]
  end
end
