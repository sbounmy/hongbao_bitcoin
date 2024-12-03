module ApplicationHelper
  def gravatar_url(email, size = 40)
    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    "https://gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=mp"
  end

  def render_payment_logo(logo)
    return placeholder_logo unless logo.attached?

    if logo.content_type == "image/svg+xml"
      raw(logo.download)
    else
      image_tag(rails_blob_path(logo, only_path: true),
        class: "w-full h-full object-contain",
        alt: "Payment method logo")
    end
  end

  private

  def placeholder_logo
    content_tag :div, class: "w-full h-full bg-white/20 rounded-lg flex items-center justify-center" do
      content_tag :span, "No logo", class: "text-white/60 text-xs"
    end
  end
end
