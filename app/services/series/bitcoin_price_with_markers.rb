# frozen_string_literal: true

module Series
  class BitcoinPriceWithMarkers < Base
    def call
      build_series
    end

    protected

    def build_series
      series = []

      date_range.each do |date|
        spot = spots_by_date[date]&.first
        timestamp = timestamp_for(date)

        if spot && spot.prices[currency.to_s]
          price = spot.prices[currency.to_s].to_f
          hong_baos = hong_baos_by_date[date]

          if hong_baos
            series << build_marker_point(timestamp, price, hong_baos)
          else
            series << [ timestamp, price ]
          end
        end
      end

      series
    end

    # Abstract methods to be implemented by subclasses
    def build_marker_point(timestamp, price, hong_baos)
      raise NotImplementedError, "Subclasses must implement build_marker_point"
    end

    def format_hong_bao_data(hong_bao)
      raise NotImplementedError, "Subclasses must implement format_hong_bao_data"
    end
  end
end
