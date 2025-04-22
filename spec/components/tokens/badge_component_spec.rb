# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tokens::BadgeComponent, type: :component do
  fixtures :all

  describe "#render" do
    context "when user has tokens" do
      it "shows positive balance" do
        render_inline(described_class.new(user: users(:satoshi)))
        expect(page).to have_css(".badge", text: "490")
      end
    end

    context "when user has no tokens" do
      it "shows zero" do
        render_inline(described_class.new(user: users(:two)))
        expect(page).to have_css(".badge", text: "0")
      end
    end

    context "when user has negative balance" do
      it "shows negative" do
        render_inline(described_class.new(user: users(:lagarde)))
        expect(page).to have_css(".badge", text: "-30")
      end
    end
  end
end
