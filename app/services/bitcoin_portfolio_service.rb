# frozen_string_literal: true

class BitcoinPortfolioService
  attr_reader :saved_hong_baos, :start_date, :end_date, :currency

  def initialize(saved_hong_baos, currency: :usd)
    @saved_hong_baos = saved_hong_baos
    @currency = currency
    @start_date = calculate_start_date
    @end_date = Date.today
  end

  def call
    {
      btc_prices: btc_price_series,
      btc_prices_with_markers: btc_price_series_with_markers,
      portfolio: portfolio_series,
      net_deposits: net_deposits_series,
      hong_bao_markers: hong_bao_markers
    }
  end

  private

  def calculate_start_date
    earliest_date = saved_hong_baos.minimum(:gifted_at)&.to_date
    return 30.days.ago.to_date if earliest_date.nil?

    # Start a bit before the earliest hong bao to show context
    # But not more than 365 days ago
    [ (earliest_date - 7.days), 365.days.ago.to_date ].max
  end

  def btc_price_series
    spots = Spot.where(date: start_date..end_date)
                .currency_exists(currency)
                .order(:date)

    spots.map do |spot|
      timestamp = spot.date.to_time.to_i * 1000
      price = spot.prices[currency.to_s].to_f
      [ timestamp, price ]
    end
  end

  def btc_price_series_with_markers
    spots = Spot.where(date: start_date..end_date)
                .currency_exists(currency)
                .order(:date)

    spots.map do |spot|
      timestamp = spot.date.to_time.to_i * 1000
      price = spot.prices[currency.to_s].to_f

      if saved_hong_baos_by_date[spot.date]
        # For Hong Bao dates, include marker configuration
        # Use Highcharts point object format
        {
          x: timestamp,
          y: price,
          marker: {
            enabled: true,
            radius: 8,
            fillColor: "#f7931a",
            lineWidth: 3,
            lineColor: "#ffffff",
            symbol: "url(favicon.svg)",
            width: 24,
            height: 24
          }
        }
      else
        # Regular points - just return array
        [ timestamp, price ]
      end
    end
  end

  def portfolio_series
    dates = (start_date..end_date).to_a

    dates.map do |date|
      value = calculate_portfolio_value_on_date(date)
      [ date.to_time.to_i * 1000, value.round(2) ]
    end
  end

  def net_deposits_series
    dates = (start_date..end_date).to_a
    cumulative_deposits = 0.0

    dates.map do |date|
      # Add deposits from Hong Baos gifted up to this date
      deposits_on_date = saved_hong_baos
        .where("gifted_at <= ?", date.end_of_day)
        .where("gifted_at > ?", date.beginning_of_day)
        .sum(&:initial_usd)

      cumulative_deposits += deposits_on_date
      [ date.to_time.to_i * 1000, cumulative_deposits.round(2) ]
    end
  end

  def saved_hong_baos_by_date
    @hb ||= saved_hong_baos.where.not(gifted_at: nil).group_by { |hb| hb.gifted_at.to_date }
  end

  def hong_bao_markers
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

  def calculate_portfolio_value_on_date(date)
    # Get all Hong Baos that existed on this date
    active_hong_baos = saved_hong_baos.where("gifted_at <= ?", date.end_of_day)

    # Get the BTC price for this date
    spot = Spot.find_by(date: date)
    return 0.0 unless spot && spot.prices[currency.to_s]

    btc_price = spot.prices[currency.to_s].to_f

    # Calculate total portfolio value
    total_btc = active_hong_baos.sum do |hb|
      # Use current_sats if we're looking at today, otherwise use initial_sats
      # This is a simplification - ideally we'd track balance history
      sats = if date == Date.today
               hb.current_sats || hb.initial_sats || 0
      else
               hb.initial_sats || 0
      end
      sats.to_f / 100_000_000
    end

    total_btc * btc_price
  end

  def current_btc_price
    @current_btc_price ||= Spot.current(currency)&.prices&.dig(currency.to_s).to_f
  end

  def calculate_price_change_percent(hong_bao)
    return 0.0 unless hong_bao.spot_buy&.prices&.dig(currency.to_s)

    initial = hong_bao.spot_buy.prices[currency.to_s].to_f
    return 0.0 if initial.zero?

    ((current_btc_price - initial) / initial * 100).round(2)
  end
end
