# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Make Sitepress site accessible
  def site
    @site ||= Sitepress.site
  end

  def render_payment_logo(logo)
    return placeholder_logo unless logo.attached?

    if logo.content_type == "image/svg+xml"
      # Wrap the raw SVG and use Tailwind's `[&>svg]` syntax to style the nested SVG.
      # This avoids manipulating the SVG string and is a cleaner approach.
      content_tag(:div, class: "h-full [&>svg]:w-full [&>svg]:h-full") do
        raw(logo.download)
      end
    else
      image_tag(logo,
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

  def youtube_icon(options = {})
    size = options.fetch(:size, 6)
    css_classes = [ "w-#{size}", "h-#{size}" ]
    css_classes << options[:class] if options[:class]

    content_tag :svg, class: css_classes.join(" "), width: 24, height: 24, viewBox: "0 0 461.001 461.001" do
      content_tag :path, nil, fill: "#F61C0D", d: "M365.257,67.393H95.744C42.866,67.393,0,110.259,0,163.137v134.728c0,52.878,42.866,95.744,95.744,95.744h269.513c52.878,0,95.744-42.866,95.744-95.744V163.137C461.001,110.259,418.135,67.393,365.257,67.393z M300.506,237.056l-126.06,60.123c-3.359,1.602-7.239-0.847-7.239-4.568V168.607c0-3.774,3.982-6.22,7.348-4.514l126.06,63.881C304.363,229.873,304.298,235.248,300.506,237.056z"
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

  def asset_to_base64(asset_name)
    # Convert static asset files to base64 data URLs
    # This is used for embedding logo images in offline pages to avoid CORS issues

    # Try app/assets/images directly first
    asset_path = Rails.root.join("app", "assets", "images", asset_name)

    # If not found, try public/assets (for precompiled assets)
    unless File.exist?(asset_path)
      asset_path = Rails.root.join("public", "assets", asset_name)
    end

    # If still not found, check other asset paths
    unless File.exist?(asset_path)
      # Search through all configured asset paths
      Rails.application.config.assets.paths.each do |path|
        potential_path = File.join(path, asset_name)
        if File.exist?(potential_path)
          asset_path = potential_path
          break
        end
      end
    end

    # Fallback to regular image_url if file not found
    return image_url(asset_name) unless File.exist?(asset_path)

    # Read the file and encode to base64
    file_content = File.read(asset_path, mode: "rb")
    base64_content = Base64.strict_encode64(file_content)

    # Determine MIME type based on file extension
    mime_type = case File.extname(asset_name).downcase
                when ".svg" then "image/svg+xml"
                when ".png" then "image/png"
                when ".jpg", ".jpeg" then "image/jpeg"
                when ".gif" then "image/gif"
                when ".webp" then "image/webp"
                else "application/octet-stream"
                end

    "data:#{mime_type};base64,#{base64_content}"
  end

  def base64_url(attachment)
    # Converts an Active Storage attachment to a Base64 data URL.
    # Returns an empty string if the attachment is not present, not attached,
    # or is not an image.
    # Check if attachment is provided, attached, and its blob is present
    return "" unless attachment.respond_to?(:attached?) && attachment.attached? && attachment.blob.present?

    blob = attachment.blob

    # Ensure it's an image type before proceeding
    return "" unless blob.content_type.start_with?("image/")

    # Download the file content from storage
    file_content = blob.download
    # Encode the content to Base64
    base64_encoded_content = Base64.strict_encode64(file_content)

  # Construct the data URL
  "data:#{blob.content_type};base64,#{base64_encoded_content}"
  end

  # Push data attributes up the layout
  # https://justin.searls.co/posts/abusing-rails-content_for-to-push-data-attributes-up-the-dom/#my-hacked-up-solution
  STUPID_SEPARATOR = "|::|::|"
  def attributes_for(name, json)
    content_for name, json.to_json.html_safe + STUPID_SEPARATOR
  end

  def attributes_from(yielded_content)
    yielded_content.split(STUPID_SEPARATOR).reduce({}) { |memo, json|
      memo.merge(JSON.parse(json)) { |key, val_1, val_2|
        token_list(val_1, val_2)
      }
    }
  end


  def theme_css(theme)
    return "" unless theme

    css = <<~CSS
      <style>
        [data-theme="#{theme.ui_name}"] {
          #{Input::Theme::UI_PROPERTIES.map { |prop|
            if value = theme.ui[prop]
              "--#{prop.dasherize}: #{value};"
            end
          }.compact.join("\n          ")}
        }
      </style>
    CSS

    css.html_safe
  end

  def section_header(title:, subtitle: nil)
    content_tag :div, class: "text-center space-y-4 pb-6 mx-auto" do
      content_tag(:h2, title, class: "text-center text-lg sm:text-xl font-semibold text-main-600") +
      content_tag(:p, subtitle, class: "mx-auto mt-2 max-w-lg text-center text-4xl font-semibold tracking-tight font-general sm:text-5xl")
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
