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


  def media_items
    image_files + external_videos
  end

  def image_files
    Dir.glob("app/assets/images/plans/#{pack}/*").map do |file_path|
      { type: :image, url: helpers.image_path("plans/#{pack}/#{File.basename(file_path)}"), name: File.basename(file_path) }
    end
  end

  def external_videos
    video_config = Rails.root.join("config/plan_videos.yml")
    return [] unless File.exist?(video_config)

    videos = YAML.load_file(video_config)[pack] || []
    videos.map.with_index do |video, idx|
      { type: video["type"].to_sym, url: video["url"], name: "external_#{idx}" }
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
