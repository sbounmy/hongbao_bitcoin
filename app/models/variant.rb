class Variant < ApplicationRecord
  include ArrayColumns

  array_columns :option_value_ids, only_integer: true

  belongs_to :product
  has_many_attached :images

  validates :sku, presence: true, uniqueness: true

  scope :master, -> { where(is_master: true) }
  scope :non_master, -> { where(is_master: false) }
  scope :ordered, -> { order(:position) }

  # SQLite-compatible scope for finding variants with specific option value
  scope :with_option_value, ->(option_value_id) {
    where("EXISTS (SELECT 1 FROM json_each(option_value_ids) WHERE value = ?)", option_value_id)
  }

  delegate :name, :description, to: :product, prefix: true

  def option_values
    @option_values ||= OptionValue.where(id: option_value_ids).includes(:option_type)
  end

  def display_name
    return product_name if is_master?
    "#{product_name} - #{options_text}"
  end

  def options_text
    option_values.map(&:presentation).join(" ")
  end

  def has_option_value?(value_id)
    option_value_ids.include?(value_id.to_i)
  end

  def primary_image
    images.first
  end

  def display_price
    "€#{price&.to_i || 0}"
  end

  def color_option_value
    option_values.find { |ov| ov.option_type.name == "color" }
  end

  def size_option_value
    option_values.find { |ov| ov.option_type.name == "size" }
  end

  def generate_sku
    return if sku.present?

    size_abbr = size_option_value&.name&.upcase || "STD"
    color_abbr = color_option_value&.name&.upcase || "DEF"
    self.sku = "#{product.slug.upcase}-#{size_abbr}-#{color_abbr}"
  end

  # Get all color option values for this variant
  def color_option_values
    option_values.select { |ov| ov.option_type.name == "color" }
  end

  # Get the display color(s) for the variant
  def display_colors
    color_option_values.filter_map(&:color)
  end

  # Get background style for the variant (inline style for dynamic colors)
  def background_style
    colors = display_colors
    return "background-color: #9ca3af" if colors.empty? # gray-400 fallback

    if colors.size > 1
      # Split color gradient - display first half one color, second half another
      "background: linear-gradient(to right, #{colors[0]} 50%, #{colors[1]} 50%)"
    else
      # Single color
      "background-color: #{colors[0]}"
    end
  end
end
