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
