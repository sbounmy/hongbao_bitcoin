# frozen_string_literal: true

module Btcdex
  class BtcPriceLedComponent < ApplicationComponent
    include ActionView::Helpers::NumberHelper

    def initialize(vs: 1.day.ago)
      @vs = vs
    end

    private

    def current_spot
      @current_spot ||= Spot.current(:usd)
    end

    def comparison_spot
      @comparison_spot ||= Spot.where("date <= ?", @vs.to_date).order(date: :desc).first
    end

    def price_change_percentage
      return 0 if comparison_spot.nil? || comparison_spot.usd.to_f.zero?
      ((current_spot.usd.to_f - comparison_spot.usd.to_f) / comparison_spot.usd.to_f * 100).round(2)
    end

    def positive_change?
      price_change_percentage >= 0
    end

    def led_color_class
      positive_change? ? "bg-success border-success/50" : "bg-error border-error/50"
    end

    def text_color_class
      positive_change? ? "text-success" : "text-error"
    end

    def formatted_price
      price = current_spot&.usd.to_i || 0
      price >= 1000 ? "$#{(price / 1000.0).round}K" : "$#{price}"
    end

    def formatted_change
      arrow = positive_change? ? "+" : ""
      "(#{arrow}#{price_change_percentage}%)"
    end
  end
end
