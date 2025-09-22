module SavedHongBaos
  class StatsComponent < ApplicationComponent
    def initialize(saved_hong_baos:)
      @saved_hong_baos = saved_hong_baos
    end

    private

    attr_reader :saved_hong_baos

    def total_count
      saved_hong_baos.count
    end

    def total_balance_btc
      saved_hong_baos.sum(&:btc)
    end

    def total_balance_usd
      saved_hong_baos.sum(&:usd)
    end

    def total_initial_usd
      saved_hong_baos.sum(&:initial_usd)
    end

    def average_gain_usd
      return 0 if saved_hong_baos.empty?
      total_gain = saved_hong_baos.sum(&:usd_change)
      total_gain
    end

    def average_gain_percentage
      return 0 if saved_hong_baos.empty? || total_initial_usd.zero?
      ((total_balance_usd - total_initial_usd) / total_initial_usd * 100)
    end

    def average_buy_price
      return 0 if saved_hong_baos.empty?

      # Calculate weighted average based on initial sats
      total_sats = saved_hong_baos.sum { |hb| hb.initial_sats || 0 }
      return 0 if total_sats.zero?

      weighted_sum = saved_hong_baos.sum do |hb|
        next 0 unless hb.initial_sats && hb.initial_sats > 0 && hb.initial_spot
        hb.initial_sats * hb.initial_spot
      end

      weighted_sum / total_sats
    end

    def median_value_usd
      return 0 if saved_hong_baos.empty?
      values = saved_hong_baos.map(&:usd).sort
      mid = values.length / 2

      if values.length.odd?
        values[mid]
      else
        (values[mid - 1] + values[mid]) / 2.0
      end
    end
  end
end
