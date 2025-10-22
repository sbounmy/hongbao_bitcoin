# frozen_string_literal: true

module Series
  class BitcoinPriceWithMarkers < Base
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

    def build_marker_point(timestamp, price, hong_baos)
      {
        x: timestamp,
        y: price,
        marker: {
          enabled: true,
          radius: 100,
          symbol: "url(#{hong_baos.first.avatar_url})",
          width: 32,
          height: 32,
          lineWidth: 2,
          lineColor: "#ffffff",
          states: {
            hover: {
              enabled: true,
              lineWidthPlus: 4,
              lineColor: "#F2A900"
            }
          }
        },
        extraData: hong_baos.map { |hb| format_hong_bao_data(hb) }
      }
    end

    def format_hong_bao_data(hong_bao)
      spot_buy_price = hong_bao.spot_buy&.prices&.dig(currency.to_s).to_f || 0
      current_value = hong_bao.btc * current_btc_price
      initial_value = hong_bao.initial_btc * spot_buy_price
      price_change_percent = initial_value.zero? ? 0 : ((current_value - initial_value) / initial_value * 100).round

      {
        id: hong_bao.id,
        recipient: hong_bao.name,
        address: hong_bao.address,
        avatarUrl: hong_bao.avatar_url,
        initialBtc: hong_bao.initial_btc,
        btc: hong_bao.btc,
        spotBuyPrice: spot_buy_price,
        initialValue: initial_value,
        currentValue: current_value,
        priceChangePercent: price_change_percent,
        status: hong_bao.status[:text]
      }
    end
  end
end
