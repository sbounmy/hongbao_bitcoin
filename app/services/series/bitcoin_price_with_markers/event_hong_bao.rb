# frozen_string_literal: true

module Series
  class BitcoinPriceWithMarkers
    class EventHongBao < BitcoinPriceWithMarkers
      private

      def build_marker_point(timestamp, price, hong_baos)
        {
          x: timestamp,
          y: price,
          marker: {
            enabled: true,
            radius: 8,
            fillColor: Simulator.event_color(hong_baos.first.event_type),
            symbol: "circle",
            lineWidth: 2,
            lineColor: "#FFFFFF"
          },
          extraData: hong_baos.map { |hb| format_hong_bao_data(hb) }
        }
      end

      def format_hong_bao_data(hong_bao)
        spot_buy_price = hong_bao.spot_buy&.prices&.dig(currency.to_s).to_f || 0
        current_value = (hong_bao.initial_sats.to_f / 100_000_000 * current_btc_price)
        initial_value = hong_bao.initial_usd

        {
          name: hong_bao.name,
          event_type: hong_bao.event_type,
          event_emoji: hong_bao.event_emoji,
          initial_sats: hong_bao.initial_sats,
          initial_usd: hong_bao.initial_usd,
          initial_price: spot_buy_price,
          current_price: current_btc_price,
          current_usd: current_value.round(2),
          change_percent: calculate_change_percent(spot_buy_price)
        }
      end

      def calculate_change_percent(initial_price)
        return 0.0 if initial_price.zero?
        ((current_btc_price - initial_price) / initial_price * 100).round(2)
      end
    end
  end
end