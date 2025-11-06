# frozen_string_literal: true

module Series
  class Portfolio < Base
    def call
      build_series
    end

    private

    def build_series
      series = []
      active_hong_baos = preload_active_hong_baos_by_date

      date_range.each do |date|
        spot = spots_by_date[date]&.first
        timestamp = timestamp_for(date)

        if spot && spot.prices[currency.to_s]
          price = spot.prices[currency.to_s].to_f
          value = calculate_portfolio_value(active_hong_baos[date] || [], price, date)
          series << [ timestamp, value.round(2) ]
        end
      end

      series
    end

    def preload_active_hong_baos_by_date
      active_by_date = {}

      # Handle both ActiveRecord relations and arrays
      hong_baos_with_dates = if saved_hong_baos.respond_to?(:where)
        saved_hong_baos
          .includes(:spot_buy) # Preload associations
          .where.not(gifted_at: nil)
          .order(:gifted_at)
          .to_a
      else
        # For arrays (like EventHongBao), filter and sort manually
        saved_hong_baos
          .select { |hb| hb.gifted_at.present? }
          .sort_by(&:gifted_at)
      end

      date_range.each do |date|
        # For now, include all hong baos gifted on or before this date
        # Status filtering will be handled separately later
        active_by_date[date] = hong_baos_with_dates.select { |hb| hb.gifted_at.to_date <= date }
      end

      active_by_date
    end

    def calculate_portfolio_value(active_hong_baos, btc_price, date)
      return 0.0 if btc_price.zero?

      total_btc = active_hong_baos.sum do |hb|
        # Use current_sats if we're looking at today, otherwise use initial_sats
        sats = if date == Date.today
                 hb.current_sats || hb.initial_sats || 0
        else
                 hb.initial_sats || 0
        end
        sats.to_f / 100_000_000
      end

      total_btc * btc_price
    end
  end
end
