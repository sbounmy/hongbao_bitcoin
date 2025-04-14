# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricingComponent, type: :component do
  let(:plans) do
    [
      { name: "Starter", tokens: 10, price: 5, stripe_price_id: "price_H5ggYwtDq4fbrJ" },
      { name: "Popular", tokens: 30, price: 10, stripe_price_id: "price_H5ggYwtDq4fbrK", default: true },
      { name: "Pro", tokens: 50, price: 15, stripe_price_id: "price_H5ggYwtDq4fbrL" }
    ]
  end

  it "renders the pricing table with all plans" do
    result = render_inline(described_class.new) do |component|
      component.with_plans(plans)
    end

    # Check if all credit amounts are present
    expect(result.text).to include("10 ₿ao")
    expect(result.text).to include("30 ₿ao")
    expect(result.text).to include("50 ₿ao")

    # Check if all prices are present
    expect(result.text).to include("$5")
    expect(result.text).to include("$10")
    expect(result.text).to include("$15")

    # Check if cost per image is calculated correctly
    expect(result.text).to include("$0.50") # 5/10
    expect(result.text).to include("$0.33") # 10/30
    expect(result.text).to include("$0.30") # 15/50

    # Check if the table headers are present
    expect(result.css(".grid-cols-4").first.text).to include(
      "Pack (Credits Included)",
      "Cost per Image",
      "Price",
      "Action"
    )

    # Check if there are 3 select buttons with Stripe price IDs
    buttons = result.css("input[name='price_id']")
    expect(buttons.count).to eq(3)
    expect(buttons[0]['value']).to eq("price_H5ggYwtDq4fbrJ")
    expect(buttons[1]['value']).to eq("price_H5ggYwtDq4fbrK")
    expect(buttons[2]['value']).to eq("price_H5ggYwtDq4fbrL")
  end

  it "shows Most Popular badge for the default plan" do
    result = render_inline(described_class.new) do |component|
      component.with_plans(plans)
    end

    # Check if Most Popular badge exists and is on the default plan
    badge = result.css(".badge").find { |b| b.text == "Most Popular" }
    expect(badge).to be_present
    expect(badge.ancestors(".relative").first.css(".grid-cols-4 div").first.text).to include("30 ₿ao")
  end
end
