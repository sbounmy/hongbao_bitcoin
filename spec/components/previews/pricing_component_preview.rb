# frozen_string_literal: true

class PricingComponentPreview < ViewComponent::Preview
  def default
    render PricingComponent.new do |component|
      component.with_plans([
        { name: "Starter", bao: 10, price: 5 },
        { name: "Popular", bao: 30, price: 10, default: true },
        { name: "Pro", bao: 50, price: 15 }
      ])
    end
  end
end
