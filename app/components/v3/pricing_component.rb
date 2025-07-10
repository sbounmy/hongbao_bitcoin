# frozen_string_literal: true

class V3::PricingComponent < ApplicationComponent
  renders_many :plans, "V3::PlanComponent"

  attr_reader :title

  def initialize(title: true)
    @title = title
  end

  # Fetch product from url param ?pack=mini|family|maximalist
  def stripe_price_id
    plans.find { |plan| plan.slug == params[:pack] }&.stripe_price_id
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

    videos = YAML.load_file(video_config)[pack] || []
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
    def initialize(name:, tokens:, description:, price:, stripe_product_id:, stripe_price_id:, envelopes:, default: false, slug:)
      @name = name
      @tokens = tokens
      @description = description
      @price = price
      @stripe_product_id = stripe_product_id
      @stripe_price_id = stripe_price_id
      @envelopes = envelopes
      @slug = slug
      @default = default
      super()
    end

    def selected?
      slug == params[:pack]
    end

    def formatted_price
      helpers.number_to_currency(price, unit: "€", format: "%n%u", strip_insignificant_zeros: true)
    end

    def formatted_description
      "#{packs} packs (#{envelopes} envelopes) + #{tokens} credits"
    end

    def packs
      envelopes / 6
    end

    attr_reader :name, :tokens, :description, :price, :default, :stripe_product_id, :stripe_price_id, :envelopes, :slug
  end
end
