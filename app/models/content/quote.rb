class Content::Quote < Content
  # Define accessors for quote metadata fields
  metadata :author, :text, :category, :full_quote

  # Alias for backward compatibility
  alias_method :quote, :text

  protected

  def generate_slug
    return if slug.present?

    base = "#{author}-#{text}".parameterize
    self.slug = base.truncate(60, omission: "")
  end

  def generate_seo_fields
    return if title.present? && h1.present?

    self.title ||= I18n.t("content.quote.title", author: author, quote: text&.truncate(50))
    self.h1 ||= I18n.t("content.quote.h1", author: author, quote: text&.truncate(60))
    self.meta_description ||= I18n.t("content.quote.meta_description", author: author, quote: text&.truncate(100))
  end
end
