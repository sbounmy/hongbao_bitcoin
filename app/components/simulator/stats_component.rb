# frozen_string_literal: true

module Simulator
  class StatsComponent < ApplicationComponent
    def initialize(event_hong_baos:)
      @event_hong_baos = event_hong_baos
    end

    private

    attr_reader :event_hong_baos

    def total_gifts_count
      event_hong_baos.size
    end

    def total_gifted_usd
      event_hong_baos.sum(&:initial_usd).round(2)
    end

    def total_bitcoin_accumulated
      sats = event_hong_baos.sum { |hb| hb.initial_sats || 0 }
      (sats.to_f / 100_000_000).round(8)
    end

    def current_portfolio_value
      current_btc_price = Spot.current(:usd)&.usd || 0
      (total_bitcoin_accumulated * current_btc_price).round(2)
    end

    def total_gain_loss
      current_portfolio_value - total_gifted_usd
    end

    def percentage_change
      return 0 if total_gifted_usd.zero?
      ((total_gain_loss / total_gifted_usd) * 100).round(2)
    end

    def average_cost_basis
      return 0 if total_bitcoin_accumulated.zero?
      (total_gifted_usd / total_bitcoin_accumulated).round(2)
    end

    def gain_loss_class
      if total_gain_loss.positive?
        "text-success"
      elsif total_gain_loss.negative?
        "text-error"
      else
        "text-base-content"
      end
    end

    def percentage_badge_class
      if percentage_change.positive?
        "badge-success"
      elsif percentage_change.negative?
        "badge-error"
      else
        "badge-ghost"
      end
    end

    def format_currency(amount)
      number_to_currency(amount.abs, unit: "$", separator: ".", delimiter: ",")
    end

    def format_bitcoin(btc)
      "₿ #{number_with_precision(btc, precision: 8, strip_insignificant_zeros: true)}"
    end
  end
end