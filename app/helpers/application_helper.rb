module ApplicationHelper
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


  def github_corner(options = {})
    css_classes = [ "absolute top-0 right-0 border-0 text-white" ]
    css_classes << options[:class] if options[:class]

    content_tag :svg, width: 80, height: 80, viewBox: "0 0 250 250", class: css_classes.join(" "), "aria-hidden": "true", fill: "#151513" do
      safe_join([
        content_tag(:path, nil, d: "M0,0 L115,115 L130,115 L142,142 L250,250 L250,0 Z"),
        content_tag(:path, nil, d: "M128.3,109.0 C113.8,99.7 119.0,89.6 119.0,89.6 C122.0,82.7 120.5,78.6 120.5,78.6 C119.2,72.0 123.4,76.3 123.4,76.3 C127.3,80.9 125.5,87.3 125.5,87.3 C122.9,97.6 130.6,101.9 134.4,103.2",
          class: "fill-current origin-[130px_106px] group-hover:animate-wave",
          style: "transform-origin: 130px 106px;"),
        content_tag(:path, nil, d: "M115.0,115.0 C114.9,115.1 118.7,116.5 119.8,115.4 L133.7,101.6 C136.9,99.2 139.9,98.4 142.2,98.6 C133.8,88.0 127.5,74.4 143.8,58.0 C148.5,53.4 154.0,51.2 159.7,51.0 C160.3,49.4 163.2,43.6 171.4,40.1 C171.4,40.1 176.1,42.5 178.8,56.2 C183.1,58.6 187.2,61.8 190.9,65.4 C194.5,69.0 197.7,73.2 200.1,77.6 C213.8,80.2 216.3,84.9 216.3,84.9 C212.7,93.1 206.9,96.0 205.4,96.6 C205.1,102.4 203.0,107.8 198.3,112.5 C181.9,128.9 168.3,122.5 157.7,114.1 C157.9,116.9 156.7,120.9 152.7,124.9 L141.0,136.5 C139.8,137.7 141.6,141.9 141.8,141.8 Z",
          class: "fill-current")
       ])
    end
  end

  def section_header(title:, subtitle:)
    content_tag :div, class: "text-center space-y-4 pb-6 mx-auto" do
      content_tag(:h2, title, class: "text-center text-lg sm:text-xl font-semibold text-main-600 dark:text-main-400") +
      content_tag(:p, subtitle, class: "mx-auto mt-2 max-w-lg text-center text-4xl font-semibold tracking-tight font-general sm:text-5xl dark:text-white")
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
