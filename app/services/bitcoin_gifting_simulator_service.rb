# frozen_string_literal: true

class BitcoinGiftingSimulatorService
  # Event configuration with emojis and date calculators
  GIFT_EVENTS = {
    christmas: {
      name: "Christmas",
      emoji: "🎄",
      calculate_date: ->(year, _opts) { Date.new(year, 12, 25) }
    },
    new_year: {
      name: "New Year",
      emoji: "🎊",
      calculate_date: ->(year, _opts) { Date.new(year, 1, 1) }
    },
    chinese_new_year: {
      name: "Chinese New Year",
      emoji: "🧧",
      calculate_date: ->(year, _opts) { ChineseNewYearService.for_year(year) }
    },
    birthday: {
      name: "Birthday",
      emoji: "🎂",
      calculate_date: ->(year, opts) {
        return nil unless opts[:birthday_month] && opts[:birthday_day]
        Date.new(year, opts[:birthday_month], opts[:birthday_day])
      }
    }
  }.freeze

  # Create a struct that mimics SavedHongBao for compatibility with existing series
  EventHongBao = Struct.new(
    :gifted_at,
    :initial_sats,
    :current_sats,
    :initial_usd,
    :name,
    :event_type,
    :event_emoji,
    :spot_buy,
    keyword_init: true
  ) do
    def user
      # Virtual user for the simulator
      OpenStruct.new(id: 0, email: "simulator@hongbao.tc")
    end

    def btc
      (current_sats || 0).to_f / 100_000_000
    end

    def initial_btc
      (initial_sats || 0).to_f / 100_000_000
    end
  end

  attr_reader :years, :events, :birthday_month, :birthday_day, :event_amounts

  def initialize(params)
    @years = params[:years] || 5
    @events = params[:events] || []
    @event_amounts = params[:event_amounts] || {}
    @birthday_month = params[:birthday_month].to_i if params[:birthday_month].present?
    @birthday_day = params[:birthday_day].to_i if params[:birthday_day].present?
    @currency = params[:currency] || :usd
  end

  def call
    event_hong_baos = generate_event_hong_baos

    # Create our own chart data since we can't use BitcoinPortfolioService directly
    # (it expects ActiveRecord relations)
    chart_data = generate_chart_data(event_hong_baos)

    {
      event_hong_baos: event_hong_baos,
      chart_data: chart_data
    }
  end

  private

  def generate_event_hong_baos
    hong_baos = []
    end_year = Date.current.year
    start_year = end_year - years + 1

    (start_year..end_year).each do |year|
      events.each do |event_key|
        event_config = GIFT_EVENTS[event_key]
        next unless event_config

        date = event_config[:calculate_date].call(
          year,
          birthday_month: birthday_month,
          birthday_day: birthday_day
        )
        next unless date
        next if date > Date.current # Don't generate future events

        # Find historical Bitcoin price for this date
        spot = Spot.where(date: date).first || find_nearest_spot(date)
        next unless spot && spot.prices[@currency.to_s]

        # Use custom amount for this event (should always be present now)
        gift_amount = event_amounts[event_key]
        next unless gift_amount && gift_amount > 0

        btc_price = spot.prices[@currency.to_s].to_f
        sats_amount = (gift_amount / btc_price * 100_000_000).to_i

        # For current value, use today's price
        current_spot = Spot.current(@currency)
        current_btc_price = current_spot&.prices&.dig(@currency.to_s).to_f || btc_price
        current_value_sats = sats_amount # Assume HODLing (no withdrawals)

        hong_baos << EventHongBao.new(
          gifted_at: date.to_time,
          initial_sats: sats_amount,
          current_sats: current_value_sats,
          initial_usd: gift_amount,
          name: "#{event_config[:name]} #{year}",
          event_type: event_key,
          event_emoji: event_config[:emoji],
          spot_buy: spot
        )
      end
    end

    # Sort by date
    hong_baos.sort_by(&:gifted_at)
  end

  def find_nearest_spot(target_date)
    # Try to find spot within 7 days before or after
    spots = Spot.where(date: (target_date - 7.days)..(target_date + 7.days))
                .currency_exists(@currency)
                .order(Arel.sql("ABS(julianday(date) - julianday('#{target_date}'))"))

    spots.first
  end

  def generate_chart_data(event_hong_baos)
    return {} if event_hong_baos.empty?

    start_date = event_hong_baos.first.gifted_at.to_date - 7.days
    end_date = Date.today

    # Prepare shared data
    spots_by_date = Spot.where(date: start_date..end_date)
                        .currency_exists(@currency)
                        .order(:date)
                        .group_by(&:date)

    hong_baos_by_date = event_hong_baos.group_by { |hb| hb.gifted_at.to_date }

    current_btc_price = Spot.current(@currency)&.prices&.dig(@currency.to_s).to_f

    shared_data = {
      spots_by_date: spots_by_date,
      hong_baos_by_date: hong_baos_by_date,
      current_btc_price: current_btc_price
    }

    # Generate series data
    {
      btc_prices: build_btc_price_series(start_date, end_date, shared_data),
      btc_prices_with_markers: build_btc_price_with_markers_series(start_date, end_date, event_hong_baos, shared_data),
      portfolio: build_portfolio_series(start_date, end_date, event_hong_baos, shared_data),
      net_deposits: build_net_deposits_series(start_date, end_date, hong_baos_by_date, shared_data),
      event_markers: build_event_markers_series(event_hong_baos, shared_data)
    }
  end

  def build_btc_price_series(start_date, end_date, shared_data)
    series = []
    (start_date..end_date).each do |date|
      spot = shared_data[:spots_by_date][date]&.first
      if spot && spot.prices[@currency.to_s]
        series << [ date.to_time.to_i * 1000, spot.prices[@currency.to_s].to_f ]
      end
    end
    series
  end

  def build_btc_price_with_markers_series(start_date, end_date, event_hong_baos, shared_data)
    series = []
    hong_baos_by_date = event_hong_baos.group_by { |hb| hb.gifted_at.to_date }

    (start_date..end_date).each do |date|
      spot = shared_data[:spots_by_date][date]&.first
      if spot && spot.prices[@currency.to_s]
        timestamp = date.to_time.to_i * 1000
        price = spot.prices[@currency.to_s].to_f

        if hong_baos_by_date[date]
          # Add marker for gift date
          series << {
            x: timestamp,
            y: price,
            marker: {
              enabled: true,
              radius: 6,
              fillColor: "#f7931a",
              lineWidth: 2,
              lineColor: "#FFFFFF"
            }
          }
        else
          series << [ timestamp, price ]
        end
      end
    end
    series
  end

  def build_portfolio_series(start_date, end_date, event_hong_baos, shared_data)
    series = []

    (start_date..end_date).each do |date|
      spot = shared_data[:spots_by_date][date]&.first
      if spot && spot.prices[@currency.to_s]
        timestamp = date.to_time.to_i * 1000
        price = spot.prices[@currency.to_s].to_f

        # Calculate portfolio value up to this date
        active_hong_baos = event_hong_baos.select { |hb| hb.gifted_at.to_date <= date }
        total_btc = active_hong_baos.sum { |hb| hb.initial_sats.to_f / 100_000_000 }
        value = total_btc * price

        series << [ timestamp, value.round(2) ]
      end
    end
    series
  end

  def build_net_deposits_series(start_date, end_date, hong_baos_by_date, shared_data)
    series = []
    cumulative_deposits = 0.0

    (start_date..end_date).each do |date|
      timestamp = date.to_time.to_i * 1000
      deposits_on_date = hong_baos_by_date[date]&.sum(&:initial_usd) || 0
      cumulative_deposits += deposits_on_date
      series << [ timestamp, cumulative_deposits.round(2) ]
    end
    series
  end

  def build_event_markers_series(event_hong_baos, shared_data)
    event_hong_baos.map do |hb|
      {
        x: hb.gifted_at.to_time.to_i * 1000,
        y: hb.spot_buy.prices[@currency.to_s].to_f,
        name: hb.name,
        event_type: hb.event_type,
        event_emoji: hb.event_emoji,
        initial_sats: hb.initial_sats,
        initial_usd: hb.initial_usd,
        initial_price: hb.spot_buy.prices[@currency.to_s].to_f,
        current_price: shared_data[:current_btc_price],
        current_usd: (hb.initial_sats.to_f / 100_000_000 * shared_data[:current_btc_price]).round(2),
        change_percent: calculate_change_percent(hb, shared_data[:current_btc_price]),
        marker: {
          enabled: true,
          radius: 8,
          fillColor: event_color(hb.event_type),
          symbol: "circle"
        }
      }
    end
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

  def calculate_change_percent(hong_bao, current_price)
    initial_price = hong_bao.spot_buy.prices[@currency.to_s].to_f
    return 0.0 if initial_price.zero?
    ((current_price - initial_price) / initial_price * 100).round(2)
  end
end
