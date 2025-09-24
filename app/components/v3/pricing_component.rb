# frozen_string_literal: true

class V3::PricingComponent < ApplicationComponent
  renders_many :plans, "V3::PlanComponent"

  attr_reader :title

  def initialize(title: true)
    @title = title
  end

  # Fetch product from url param ?pack=mini|family|maximalist
  def stripe_price_id
    plans.find { |plan| plan.product.slug == params[:pack] }&.stripe_price_id
  end

  def pack
    params[:pack] || "mini"
  end

  def color
    params[:color] || "red"
  end


  def media_items
    image_files + video_files
  end

  def image_files
    folder = image_folder_name
    path_pattern = "app/assets/images/plans/#{pack}/#{folder}/*"
    Dir.glob(path_pattern).select { |f| File.file?(f) }.map do |file_path|
      { type: :image, url: helpers.image_path("plans/#{pack}/#{folder}/#{File.basename(file_path)}"), name: File.basename(file_path) }
    end
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

  def image_folder_name
    colors = color.split(",")
    base_path = Rails.root.join("app/assets/images/plans", pack)
    # get a list of all directory names, for example we have ["001_red", "005_split_orange_red"]
    all_folders = Dir.glob(base_path.join("*")).select { |p| File.directory?(p) }.map { |p| File.basename(p) }

    if colors.size > 1
      # for split colors, find the folder that contains the right combination.
      permutations = colors.permutation.map { |p| "split_#{p.join('_')}" }
      all_folders.find { |folder| permutations.any? { |perm| folder.include?(perm) } } || colors.first
    else
      # for single colors, find the folder that ends with the color name.
      color_name = colors.first
      all_folders.find { |folder| folder.end_with?("_#{color_name}") } || color_name
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
      product.slug == params[:pack]
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
      product.master_variant&.stripe_price_id || product.default_variant&.stripe_price_id
    end
  end
end
