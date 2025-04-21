class InstagramPost < ApplicationRecord
  validates :media_url, :permalink, :published_at, presence: true
  validates :active, inclusion: [true, false]
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # Optional: Validate uniqueness if you added the unique index
  # validates :instagram_id, uniqueness: true, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, published_at: :desc) }

  # Allow specific attributes for searching/filtering in Active Admin
  def self.ransackable_attributes(auth_object = nil)
    ["active", "caption", "created_at", "id", "instagram_id", "media_type", "media_url", "permalink", "position", "published_at", "updated_at"]
  end

  # Optional: If you want to allow searching through associations in the future
  # def self.ransackable_associations(auth_object = nil)
  #   [] # Add association names here, e.g., ["user"]
  # end

  # Optional: Helper to show a preview in Active Admin
  def image_preview
    # Consider a slightly more flexible regex if URLs might have query params
    if media_url.present? && media_url.match?(/\.(jpe?g|gif|png)(\?|$)/i)
      helpers.image_tag(media_url, height: '100')
    else
      "No image preview" # Or "Preview not available for this media type"
    end
  end

  private

  def helpers
    ActionController::Base.helpers
  end
end