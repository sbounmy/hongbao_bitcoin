# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricingComponent, type: :component do
  it "renders the pricing table with all plans" do
    result = render_inline(described_class.new) do |component|
      component.with_plans([
        { name: "Starter", bao: 10, price: 5 },
        { name: "Popular", bao: 30, price: 10, default: true },
        { name: "Pro", bao: 50, price: 15 }
      ])
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

    # Check if there are 3 select buttons
    expect(result.css("button").count).to eq(3)
  end

  it "shows Most Popular badge for the default plan" do
    result = render_inline(described_class.new) do |component|
      component.with_plans([
        { name: "Starter", bao: 10, price: 5 },
        { name: "Popular", bao: 30, price: 10, default: true },
        { name: "Pro", bao: 50, price: 15 }
      ])
    end

    # Check if Most Popular badge exists and is on the default plan
    badge = result.css(".badge").find { |b| b.text == "Most Popular" }
    expect(badge).to be_present
    expect(badge.ancestors(".relative").first.css(".grid-cols-4 div").first.text).to include("30 ₿ao")
  end
end
