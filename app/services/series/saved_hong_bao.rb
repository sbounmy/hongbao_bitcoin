# frozen_string_literal: true

module Series
  class SavedHongBao < Base
    def call
      build_markers
    end

    private

    def build_markers
      saved_hong_baos.map do |hb|
        next unless hb.gifted_at && hb.spot_buy

        {
          x: hb.gifted_at.to_date.to_time.to_i * 1000,
          y: hb.spot_buy.prices[currency.to_s].to_f,
          name: hb.name,
          address: hb.address,
          initial_sats: hb.initial_sats,
          current_sats: hb.current_sats,
          initial_price: hb.spot_buy.prices[currency.to_s].to_f,
          current_price: current_btc_price,
          change_percent: calculate_price_change_percent(hb)
        }
      end.compact
    end

    def calculate_price_change_percent(hong_bao)
      return 0.0 unless hong_bao.spot_buy&.prices&.dig(currency.to_s)

      initial = hong_bao.spot_buy.prices[currency.to_s].to_f
      return 0.0 if initial.zero?

      ((current_btc_price - initial) / initial * 100).round(2)
    end
  end
end