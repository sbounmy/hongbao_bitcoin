# frozen_string_literal: true

module Series
  class NetDeposit < Base
    def call
      build_series
    end

    private

    def build_series
      series = []
      cumulative_deposits = 0.0

      date_range.each do |date|
        timestamp = timestamp_for(date)
        hong_baos = hong_baos_by_date[date]
        deposits_on_date = hong_baos&.sum(&:initial_usd) || 0
        cumulative_deposits += deposits_on_date

        series << [timestamp, cumulative_deposits.round(2)]
      end

      series
    end
  end
end