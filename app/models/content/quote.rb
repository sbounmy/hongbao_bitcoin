class Content::Quote < Content
  metadata :author, :text

  # Override parent's friendly_id to use slug_candidates
  friendly_id :slug_candidates, use: [ :slugged, :history ]

  def best_image
    if hongbao_products.published.first&.image&.attached?
      hongbao_products.published.first.image
    elsif avatar.attached?
      avatar
    end
  end

  # FriendlyId will try these in order until it finds one that's unique
  def slug_candidates
    [
      [ :author, :text ],
      [ :author, :text, :id ]
    ]
  end

  # Override to normalize the text without truncating
  def normalize_friendly_id(value)
    value.to_s.parameterize(preserve_case: false)
  end

  protected

  def should_generate_new_friendly_id?
    author_changed? || text_changed? || super
  end

  def generate_seo_fields
    return if title.present? && h1.present?

    self.title ||= I18n.t("content.quote.title", author: author, quote: text&.truncate(50))
    self.h1 ||= I18n.t("content.quote.h1", author: author, quote: text&.truncate(60))
    self.meta_description ||= I18n.t("content.quote.meta_description", author: author, quote: text&.truncate(100))
  end
end
