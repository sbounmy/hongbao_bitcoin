class Content::Quote < Content
  # Define accessors for quote metadata fields
  metadata :author, :quote, :year, :category, :gradient, :icon, :source, :full_quote

  # Alias for cleaner API
  alias_method :quote_text, :quote


  protected

  def generate_slug
    return if slug.present?

    base = "#{author}-#{quote}".parameterize
    self.slug = base.truncate(60, omission: "")
  end

  def generate_seo_fields
    return if title.present? && h1.present?

    self.title ||= I18n.t("content.quote.title", author: author, quote: quote&.truncate(50))
    self.h1 ||= I18n.t("content.quote.h1", author: author, quote: quote&.truncate(60))
    self.meta_description ||= I18n.t("content.quote.meta_description", author: author, quote: quote&.truncate(100))
  end
end
