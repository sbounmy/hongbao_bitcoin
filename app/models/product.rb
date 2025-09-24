class Product < ApplicationRecord
  include ArrayColumns
  include Metadata

  extend FriendlyId
  friendly_id :name, use: :slugged

  array_columns :option_type_ids, only_integer: true
  store_accessor :metadata, :envelopes_count, :tokens_count

  has_many :variants, -> { order(:position) }, dependent: :destroy
  belongs_to :master_variant, class_name: "Variant", optional: true

  validates :name, presence: true

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :ordered, -> { order(:position) }

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

  def find_variant_by_options(option_value_ids)
    variants.find { |v| v.option_value_ids.sort == option_value_ids.sort }
  end

  def variant_for_color(color_name)
    color_value = OptionValue.find_by_name_and_type(color_name, "color")
    return nil unless color_value

    variants.find { |v| v.has_option_value?(color_value.id) }
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
