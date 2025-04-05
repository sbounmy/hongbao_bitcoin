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

  def cuttable_content(options = {}, &block)
    wrapper_classes = [
      "relative",           # For scissors positioning
      "border-2",
      "border-dashed",
      "border-gray-400",
      "inline-block",      # To fit content size
      options[:class]      # Allow additional classes
    ].compact.join(" ")

    content_tag(:div, class: wrapper_classes, style: options[:style]) do
      concat(scissors_icon)
      concat(capture(&block))
    end
  end

  def github_icon(options = {})
    size = options.fetch(:size, 6)
    css_classes = [ "w-#{size}", "h-#{size}" ]
    css_classes << options[:class] if options[:class]

    content_tag :svg, class: css_classes.join(" "), viewBox: "0 0 24 24", fill: "currentColor" do
      content_tag :path, nil, fill_rule: "evenodd", clip_rule: "evenodd", d: "M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"
    end
  end

  private

  def placeholder_logo
    content_tag :div, class: "w-full h-full bg-white/20 rounded-lg flex items-center justify-center" do
      content_tag :span, "No logo", class: "text-white/60 text-xs"
    end
  end

  def scissors_icon
    # ... existing scissors_icon code ...
  end
end
