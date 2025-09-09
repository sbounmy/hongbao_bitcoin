class Content < ApplicationRecord
  include Metadata

  validates :slug, presence: true, uniqueness: true

  # Active Storage attachments
  has_one_attached :image
  has_one_attached :avatar  # For quotes with author avatars

  # Self-referential associations
  belongs_to :parent, class_name: "Content", optional: true
  has_many :children, class_name: "Content", foreign_key: "parent_id", dependent: :destroy
  has_many :products, -> { where(type: "Content::Product") }, class_name: "Content::Product", foreign_key: "parent_id"

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :root_content, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :created_at) }

  before_validation :generate_slug, on: :create
  before_save :generate_seo_fields


  # Convert class name to URL-friendly plural form
  # 'quotes' => Content::Quote
  # 'artists' =>Content::Artist
  def self.content_types
    descendants.each_with_object({}) do |klass, hash|
      key = klass.name.demodulize.downcase.pluralize
      hash[key] = klass
    end
  end

  def to_param
    slug
  end

  def content_type
    # For backwards compatibility and URL generation
    self.class.name.downcase
  end

  # Helper methods for products
  def featured_products
    products.where("metadata->>'featured' = ?", "true")
  end

  def hongbao_products
    products.where("metadata->>'shop' = ?", "Hong₿ao")
  end

  def external_products
    products.where("metadata->>'shop' != ?", "Hong₿ao")
  end

  protected

  def generate_slug
    nil if slug.present?
    # To be overridden by subclasses
  end

  def generate_seo_fields
    # To be overridden by subclasses
  end
end
