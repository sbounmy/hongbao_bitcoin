# frozen_string_literal: true

class PricingComponent < ApplicationComponent
  renders_many :plans, "PlanComponent"

  class PlanComponent < ViewComponent::Base
    def initialize(name:, tokens:, price:, stripe_price_id:, default: false)
      @name = name
      @tokens = tokens
      @price = price
      @stripe_price_id = stripe_price_id
      @default = default
      super()
    end

    private

    attr_reader :name, :tokens, :price, :default, :stripe_price_id
  end
end
