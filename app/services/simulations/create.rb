# frozen_string_literal: true

module Simulations
  class Create < ApplicationService
    def call(params)
      @years = params[:years] || 5
      @events = params[:events] || []
      @event_amounts = params[:event_amounts] || {}
      @birthday_month = params[:birthday_month].to_i if params[:birthday_month].present?
      @birthday_day = params[:birthday_day].to_i if params[:birthday_day].present?
      @currency = params[:currency] || :usd
      @stats_only = params[:stats_only] || false

      event_hong_baos = generate_event_hong_baos

      # Only generate chart data if not in stats_only mode
      chart_data = @stats_only ? {} : generate_chart_data(event_hong_baos)

      success({
        event_hong_baos: event_hong_baos,
        chart_data: chart_data
      })
    end

    private

    def generate_event_hong_baos
      hong_baos = []
      end_year = Date.current.year
      start_year = end_year - @years + 1

      (start_year..end_year).each do |year|
        @events.each do |event_key|
          event_config = Simulation.event_config(event_key)
          next unless event_config

          date = Simulation.calculate_event_date(
            event_key,
            year,
            birthday_month: @birthday_month,
            birthday_day: @birthday_day
          )
          next unless date
          next if date > Date.current # Don't generate future events

          # Find historical Bitcoin price for this date
          spot = Spot.where(date: date).first || find_nearest_spot(date)
          next unless spot && !spot.prices[@currency.to_s].nil?

          # Use custom amount for this event
          gift_amount = @event_amounts[event_key]
          next unless gift_amount && gift_amount > 0

          btc_price = spot.prices[@currency.to_s].to_f
          sats_amount = (gift_amount / btc_price * 100_000_000).to_i

          # For current value, use today's price (but we assume HODLing)
          current_value_sats = sats_amount # Assume HODLing (no withdrawals)

          hong_baos << Simulation::EventHongBao.new(
            gifted_at: date.to_time,
            initial_sats: sats_amount,
            current_sats: current_value_sats,
            initial_usd: gift_amount,
            name: "#{event_config[:label]} #{year}",
            event_type: event_key,
            event_emoji: event_config[:emoji],
            event_color: event_config[:color],
            spot_buy: spot
          )
        end
      end

      # Sort by date
      hong_baos.sort_by(&:gifted_at)
    end

    def find_nearest_spot(target_date)
      # Try to find spot within 7 days before or after
      quoted_date = Spot.connection.quote(target_date.to_s)
      spots = Spot.where(date: (target_date - 7.days)..(target_date + 7.days))
                  .currency_exists(@currency)
                  .order(Arel.sql("ABS(julianday(date) - julianday(#{quoted_date}))"))

      spots.first
    end

    def generate_chart_data(event_hong_baos)
      return {} if event_hong_baos.empty?

      start_date = event_hong_baos.first.gifted_at.to_date - 7.days
      end_date = Date.today

      # Prepare shared data for all series builders
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

      # Use existing Series services to build chart data
      {
        btc_prices: Series::BitcoinPrice.new(
          event_hong_baos,
          start_date: start_date,
          end_date: end_date,
          currency: @currency,
          shared_data: shared_data
        ).call,
        btc_prices_with_markers: Series::BitcoinPriceWithMarkers::EventHongBao.new(
          event_hong_baos,
          start_date: start_date,
          end_date: end_date,
          currency: @currency,
          shared_data: shared_data
        ).call,
        portfolio: Series::Portfolio.new(
          event_hong_baos,
          start_date: start_date,
          end_date: end_date,
          currency: @currency,
          shared_data: shared_data
        ).call,
        net_deposits: Series::NetDeposit.new(
          event_hong_baos,
          start_date: start_date,
          end_date: end_date,
          currency: @currency,
          shared_data: shared_data
        ).call,
        event_markers: Series::EventHongBao.new(
          event_hong_baos,
          start_date: start_date,
          end_date: end_date,
          currency: @currency,
          shared_data: shared_data
        ).call
      }
    end
  end
end
