class Content::Product < Content
  # Product-specific validations
  validates :parent_id, presence: true # Products must belong to a parent content (quote, artist, etc.)

  # Define accessors for product metadata fields
  metadata :title, :shop, :price, :currency, :url, :affiliate_url, :commission, :featured, :description, :icon

  # Aliases for cleaner API
  alias_method :product_url, :url

  # Scopes
  scope :featured, -> { where("metadata->>'featured' = ?", "true") }
  scope :internal, -> { where("metadata->>'shop' = ?", "Hong₿ao") }
  scope :external, -> { where("metadata->>'shop' != ?", "Hong₿ao") }
  scope :by_shop, ->(shop) { where("metadata->>'shop' = ?", shop) }

  def featured?
    featured == true || featured == "true"
  end

  def internal?
    shop == "Hong₿ao"
  end

  def external?
    !internal?
  end

  # Override slug generation for products
  protected

  def generate_slug
    return if slug.present?
    base_slug = title&.parameterize || "product-#{SecureRandom.hex(4)}"
    self.slug = "#{base_slug}-#{shop.parameterize}"
  end

  def generate_seo_fields
    # title field in the contents table, not the data field
    self.attributes["title"] ||= self.title
    self.meta_description ||= "#{self.title} - Available at #{shop}. #{description}".truncate(160) if self.title
  end
end
