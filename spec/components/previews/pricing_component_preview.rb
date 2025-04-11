# frozen_string_literal: true

class PricingComponentPreview < ViewComponent::Preview
  def default
    render PricingComponent.new do |component|
      component.with_plans([
        { name: "Starter", bao: 10, price: 5, stripe_price_id: "price_H5ggYwtDq4fbrJ" },
        { name: "Popular", bao: 30, price: 10, stripe_price_id: "price_H5ggYwtDq4fbrK", default: true },
        { name: "Pro", bao: 50, price: 15, stripe_price_id: "price_H5ggYwtDq4fbrL" }
      ])
    end
  end
end
