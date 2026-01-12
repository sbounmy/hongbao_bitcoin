class Input::Theme < Input
  POSITION = 1

  self.renderable = true

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
    "resolution"
  ].freeze

  # Element type definitions for visual editor
  ELEMENT_TYPES = {
    "shape" => {
      properties: [ "x", "y", "width", "height", "color", "opacity" ],
      uses_size: false
    },
    "text" => {
      properties: [ "x", "y", "width", "height", "size", "color", "opacity" ],
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

  def self.default_elements
    {
      "private_key_qrcode" => {
        "x" => 12,
        "y" => 38,
        "width" => 17,
        "height" => 17,
        "color" => "224, 120, 1",
        "opacity" => 1.0,
        "type" => "private_key/qrcode",
        "side" => "back"
      },
      "private_key_text" => {
        "x" => 15,
        "y" => 35,
        "width" => 12,
        "height" => 10,
        "size" => 1.8,
        "color" => "224, 120, 1",
        "opacity" => 1.0,
        "type" => "private_key/text",
        "side" => "back"
      },
      "public_address_qrcode" => {
        "x" => 55,
        "y" => 24,
        "width" => 25,
        "height" => 25,
        "color" => "224, 120, 1",
        "opacity" => 1.0,
        "type" => "public_address/qrcode",
        "side" => "front"
      },
      "public_address_text" => {
        "x" => 55,
        "y" => 24,
        "width" => 12,
        "height" => 10,
        "size" => 1.8,
        "color" => "0, 0, 0",
        "opacity" => 1.0,
        "type" => "public_address/text",
        "side" => "front"
      },
      "mnemonic_text" => {
        "x" => 20,
        "y" => 20,
        "width" => 12,
        "height" => 15,
        "size" => 1.6,
        "color" => "0, 0, 0",
        "opacity" => 1.0,
        "type" => "mnemonic/text",
        "side" => "back"
      },

      "portrait" => {
        "x" => 11.31,              # percentage from left
        "y" => 12.26,               # percentage from top
        "width" => 79,          # percentage of template width
        "height" => 36,         # percentage of template height
        "color" => "",          # Tone color (hex) - empty means no tint
        "opacity" => 0.25,      # Tone opacity (0.0 - 1.0)
        "resolution" => "1024x1024",  # AI generation size: 1024x1024, 1536x1024, 1024x1536
        "type" => "image",
        "side" => "front"
      }
    }
  end

  has_one_attached :image_hero do |attachable|
    attachable.variant :webp, convert: :webp
  end
  has_one_attached :image_back do |attachable|
    attachable.variant :webp, convert: :webp
  end
  has_one_attached :image_front do |attachable|
    attachable.variant :webp, convert: :webp
  end

  validates :slug, presence: true, uniqueness: true

  metadata :spotify, accessors: [ :path ], prefix: true
  metadata :frame
  metadata :elements


  # Override elements to provide defaults when empty
  def elements
    result = super
    result.presence || self.class.default_elements
  end

  # Parse JSON string from form submissions
  def elements=(value)
    if value.is_a?(String)
      super(JSON.parse(value))
    else
      super(value)
    end
  rescue JSON::ParserError
    super(value)
  end



  # Helper method to get portrait configuration with defaults
  def portrait_config
    elements["portrait"] || self.class.default_elements["portrait"]
  end

  # Override frame getter to provide default value
  def frame
    super || "landscape"
  end

  # Frame object for handling paper orientation and dimensions
  def frame_object
    @frame_object ||= Frame.new(frame)
  end

  delegate :width, :height, :aspect_ratio, :css_classes,
           :rotation_front, :rotation_back, :fold_line, to: :frame_object
end
