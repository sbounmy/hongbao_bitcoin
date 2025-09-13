class Content::Artist < Content
  # Define accessors for artist metadata fields
  metadata :name, :bio, :style, :website, :portfolio_url, :commission_available

  protected

  def generate_slug
    return if slug.present?
    self.slug = name&.parameterize || "artist-#{SecureRandom.hex(4)}"
  end

  def generate_seo_fields
    return if attributes["title"].present? && h1.present?

    self.attributes["title"] ||= I18n.t("content.artist.title", name: name, style: style)
    self.h1 ||= I18n.t("content.artist.h1", name: name)
    self.meta_description ||= I18n.t("content.artist.meta_description", name: name, bio: bio&.truncate(100))
  end
end
