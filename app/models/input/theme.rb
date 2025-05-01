class Input::Theme < Input
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
    "mnemonic_text"
  ].freeze

  AI_ELEMENT_PROPERTIES = Set[
    "x",
    "y",
    "size",
    "color",
    "max_text_width"
  ].freeze

  AI_PROPERTIES = AI_ELEMENT_TYPES.index_with { |_type| AI_ELEMENT_PROPERTIES }.freeze

  has_one_attached :hero_image
  validates :ui_name, presence: true
  validates :slug, presence: true, uniqueness: true

  store :metadata, accessors: [ :ui , :ai]
  store :ui, accessors: [ :name ] + UI_PROPERTIES, prefix: true

  before_save :delete_empty_ui_properties

  def ui_name
   super || "cyberpunk"
  end

  # We cannot set null / empty for color picker so when its default value we remove it
  # https://github.com/whatwg/html/issues/9572
  def delete_empty_ui_properties
    ui.delete_if { |key, value| value.blank? || value == "#000000" }
  end
end
