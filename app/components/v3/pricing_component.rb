# frozen_string_literal: true

class V3::PricingComponent < ApplicationComponent
  renders_many :plans, "V3::PlanComponent"

  attr_reader :title

  def initialize(title: true)
    @title = title
  end

  # Fetch product from url param ?pack=mini|family|maximalist
  def stripe_price_id
    selected_variant&.stripe_price_id
  end

  def selected_product
    plans.find { |plan| plan.product.slug == pack }&.product
  end

  def selected_variant
    selected_product.variants.find_by(id: params[:variant_id]) || selected_product.variants.first
  end

  def pack
    params[:pack] || "mini"
  end

  def color
    selected_variant&.color_option_value&.name
  end


  def media_items
    image_files
  end

  def image_files
    selected_variant&.images&.map do |attachment|
      { type: :image, url: helpers.url_for(attachment), name: attachment.filename.to_s }
    end || []
  end

  def video_files
    video_config = Rails.root.join("config/plan_videos.yml")
    return [] unless File.exist?(video_config)

    all_videos = YAML.load_file(video_config)
    plan_videos = all_videos[pack]
    return [] unless plan_videos

    selected_colors = color.split(",")
    videos = selected_colors.flat_map { |c| plan_videos[c] || [] }.compact

    videos.map.with_index do |video, idx|
      { type: video["type"].to_sym, url: video["url"], name: "external_#{idx}" }
    end
  end

  class V3::PlanComponent < ViewComponent::Base
    attr_reader :product, :default

    def initialize(product:, default: false)
      @product = product
      @default = default
      super()
    end

    def selected?
      product.slug == pack
    end

    def pack
      params[:pack] || "mini"
    end

    def formatted_price
      helpers.number_to_currency(product.price, unit: "€", format: "%n%u", strip_insignificant_zeros: true)
    end

    def formatted_description
      "#{packs} packs (#{product.envelopes_count} envelopes) + #{product.tokens_count} credits"
    end

    def price_per_envelope
      (product.price.to_f / product.envelopes_count).round(2)
    end

    def formatted_price_per_envelope
      helpers.number_to_currency(price_per_envelope, unit: "€", format: "%n%u")
    end

    def packs
      product.envelopes_count / 6
    end

    def stripe_price_id
      selected_variant&.stripe_price_id
    end
  end
end
