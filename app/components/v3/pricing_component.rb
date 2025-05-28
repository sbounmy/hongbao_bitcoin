# frozen_string_literal: true

class V3::PricingComponent < ApplicationComponent
  renders_many :plans, "V3::PlanComponent"

  attr_reader :title

  def initialize(title: true)
    @title = title
  end

  class V3::PlanComponent < ViewComponent::Base
    def initialize(name:, tokens:, description:, price:, stripe_product_id:, stripe_price_id:, envelopes:, default: false)
      @name = name
      @tokens = tokens
      @description = description
      @price = price
      @stripe_product_id = stripe_product_id
      @stripe_price_id = stripe_price_id
      @envelopes = envelopes
      @default = default
      super()
    end

    def formatted_price
      helpers.number_to_currency(price, unit: "€", format: "%n%u", strip_insignificant_zeros: true)
    end

    private

    attr_reader :name, :tokens, :description, :price, :default, :stripe_product_id, :stripe_price_id, :envelopes
  end
end
