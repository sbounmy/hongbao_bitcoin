# frozen_string_literal: true

class V3::PricingComponent < ApplicationComponent
  attr_reader :product, :title

  def initialize(product:, title: true)
    super()
    @product = product
    @title = title
  end

  def stripe_price_id
    selected_variant&.stripe_price_id
  end

  # The selected variant - either from URL param or default
  def selected_variant
    @selected_variant ||= if params[:variant_id].present?
      product.variants.find_by(id: params[:variant_id])
    else
      # Default to first non-master variant
      product.variants.find { |v| !v.is_master }
    end
  end

  def selected_variant_id
    selected_variant&.id
  end

  # Derive size from selected variant
  def selected_size
    @selected_size ||= selected_variant&.size_option_value
  end

  def selected_size_id
    selected_size&.id
  end

  # Derive color from selected variant
  def selected_color
    @selected_color ||= selected_variant&.color_option_value
  end

  # Filter variants to only those matching the selected size (for color selector)
  def variants_for_selected_size
    product.variants.select { |v| v.size_option_value&.id == selected_size&.id }
  end

  def color
    selected_variant&.color_option_value&.name
  end

  def media_items
    image_files + video_files
  end

  def image_files
    # Use product.all_images to get variant images first, then product images
    product.all_images(selected_variant).map do |attachment|
      { type: :image, url: helpers.url_for(attachment), name: attachment.filename.to_s }
    end
  end

  def video_files
    video_config = Rails.root.join("config/plan_videos.yml")
    return [] unless File.exist?(video_config)

    all_videos = YAML.load_file(video_config)
    size_name = selected_size&.name || "mini"
    plan_videos = all_videos[size_name]
    return [] unless plan_videos

    color_name = color || "red"
    selected_colors = color_name.split(",")
    videos = selected_colors.flat_map { |c| plan_videos[c] || [] }.compact

    videos.map.with_index do |video, idx|
      { type: video["type"].to_sym, url: video["url"], name: "external_#{idx}" }
    end
  end
end
