# frozen_string_literal: true

module Series
  class EventHongBao < Base
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
          event_type: hb.event_type,
          event_emoji: hb.event_emoji,
          initial_sats: hb.initial_sats,
          current_sats: hb.current_sats,
          initial_price: hb.spot_buy.prices[currency.to_s].to_f,
          current_price: current_btc_price,
          initial_usd: hb.initial_usd,
          current_usd: calculate_current_value(hb),
          change_percent: calculate_price_change_percent(hb),
          marker: {
            enabled: true,
            radius: 8,
            symbol: "circle",
            fillColor: event_color(hb.event_type),
            lineWidth: 2,
            lineColor: "#FFFFFF"
          }
        }
      end.compact
    end

    def calculate_current_value(hong_bao)
      return 0.0 unless current_btc_price > 0

      btc_amount = (hong_bao.current_sats || 0).to_f / 100_000_000
      (btc_amount * current_btc_price).round(2)
    end

    def calculate_price_change_percent(hong_bao)
      return 0.0 unless hong_bao.spot_buy&.prices&.dig(currency.to_s)

      initial = hong_bao.spot_buy.prices[currency.to_s].to_f
      return 0.0 if initial.zero?

      ((current_btc_price - initial) / initial * 100).round(2)
    end

    def event_color(event_type)
      case event_type
      when :christmas
        "#dc2626"       # Red for Christmas
      when :new_year
        "#f59e0b"       # Orange for New Year
      when :chinese_new_year
        "#ef4444"       # Bright red for Chinese New Year
      when :birthday
        "#ec4899"       # Pink for Birthday
      else
        "#6b7280"       # Gray for unknown events
      end
    end
  end
end