# frozen_string_literal: true

class PricingComponent < ViewComponent::Base
  renders_many :plans, "PlanComponent"

  class PlanComponent < ViewComponent::Base
    def initialize(name:, bao:, price:, default: false)
      @name = name
      @bao = bao
      @price = price
      @default = default
      super()
    end

    private

    attr_reader :name, :bao, :price, :default
  end
end
