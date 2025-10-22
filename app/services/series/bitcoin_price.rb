# frozen_string_literal: true

module Series
  class BitcoinPrice < Base
    def call
      build_series
    end

    private

    def build_series
      series = []

      date_range.each do |date|
        spot = spots_by_date[date]&.first
        timestamp = timestamp_for(date)

        if spot && spot.prices[currency.to_s]
          price = spot.prices[currency.to_s].to_f
          series << [timestamp, price]
        end
      end

      series
    end
  end
end