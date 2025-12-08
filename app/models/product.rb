class Product < ApplicationRecord
  include ArrayColumns
  include Metadata

  extend FriendlyId
  friendly_id :name, use: :slugged

  array_columns :option_type_ids, only_integer: true

  has_many :variants, -> { order(:position) }, dependent: :destroy
  belongs_to :master_variant, class_name: "Variant", optional: true
  has_many_attached :images

  validates :name, presence: true

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :ordered, -> { order(:position) }
  scope :with_variants, -> { includes(variants: { images_attachments: :blob }, images_attachments: :blob) }

  # SQLite-compatible scope for finding products with specific option type
  scope :with_option_type, ->(option_type_id) {
    where("EXISTS (SELECT 1 FROM json_each(option_type_ids) WHERE value = ?)", option_type_id)
  }

  after_create :create_master_variant

  def option_types
    OptionType.where(id: option_type_ids)
  end

  def available_variants
    variants.includes(:images_attachments)
  end

  def default_variant
    # Prefer variant with stripe_price_id (regardless of is_master status), then master, then first
    variants.where.not(stripe_price_id: nil).where.not(stripe_price_id: "").first ||
      variants.find_by(is_master: true) ||
      master_variant ||
      variants.first
  end

  def price
    # Get price from first non-master variant with a price, or default variant
    variants.non_master.where.not(price: nil).where.not(price: 0).first&.price ||
      default_variant&.price ||
      0
  end

  def display_price
    "€#{price&.to_i || 0}"
  end

  def envelopes_count
    default_variant&.envelopes_count || 6
  end

  def tokens_count
    default_variant&.tokens_count || 12
  end

  def find_variant_by_options(option_value_ids)
    variants.find { |v| v.option_value_ids.sort == option_value_ids.sort }
  end

  # Generic: find variant by any option value name (color, size, material, etc.)
  def find_variant_by_param(option_name)
    return nil if option_name.blank?

    # Find matching option value across ALL option types
    option_value = OptionValue.find_by(name: option_name.to_s.downcase)
    return nil unless option_value

    variants.find { |v| v.has_option_value?(option_value.id) }
  end

  # URL-friendly identifier for the variant (first distinguishing option)
  def variant_url_param(variant)
    variant&.option_values&.first&.name
  end

  # Keep for backwards compatibility
  def variant_for_color(color_name)
    find_variant_by_param(color_name)
  end

  # Returns variant images first, then product images (common to all variants)
  def all_images(variant = nil)
    variant_images = variant&.images&.to_a || []
    product_images = images.to_a
    variant_images + product_images
  end

  private

  def create_master_variant
    return if master_variant.present?

    variant = variants.create!(
      sku: "#{slug.upcase}-MASTER",
      is_master: true,
      price: 0
    )
    update_column(:master_variant_id, variant.id)
  end
end
