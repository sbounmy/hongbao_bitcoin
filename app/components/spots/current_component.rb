# frozen_string_literal: true

module Spots
  class CurrentComponent < ApplicationComponent
    attr_reader :vs, :currency

    def initialize(vs: 1.day.ago, currency: :usd)
      @vs = vs
      @currency = currency
      super()
    end

    private

    def current_spot
      @current_spot ||= Spot.current(currency)
    end

    def comparison_spot
      @comparison_spot ||= Spot.where("date <= ?", vs.to_date).order(date: :desc).first
    end

    def current_price
      return 0 unless current_spot
      current_spot.public_send(currency).to_f
    end

    def comparison_price
      return 0 unless comparison_spot
      comparison_spot.public_send(currency).to_f
    end

    def price_change
      return 0 if comparison_price.zero?
      current_price - comparison_price
    end

    def price_change_percentage
      return 0 if comparison_price.zero?
      ((price_change / comparison_price) * 100).round(2)
    end

    def currency_symbol
      case currency
      when :usd
        "$"
      when :eur
        "€"
      else
        ""
      end
    end

    def positive_change?
      price_change >= 0
    end

    def last_updated
      return "N/A" unless current_spot&.updated_at
      "#{time_ago_in_words(current_spot.updated_at)} ago"
    end
  end
end
