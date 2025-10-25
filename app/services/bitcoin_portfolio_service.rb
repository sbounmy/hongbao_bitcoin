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
    # Preload shared data once to avoid n+1 queries
    shared_data = preload_shared_data

    # Build all series using separate classes with shared data
    {
      btc_prices: build_btc_price_series(shared_data),
      btc_prices_with_markers: build_btc_price_with_markers_series(shared_data),
      portfolio: build_portfolio_series(shared_data),
      net_deposits: build_net_deposits_series(shared_data),
      hong_bao_markers: build_hong_bao_markers_series(shared_data)
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

  def preload_shared_data
    {
      spots_by_date: load_spots_by_date,
      hong_baos_by_date: load_hong_baos_by_date,
      current_btc_price: Spot.current(currency)&.prices&.dig(currency.to_s).to_f
    }
  end

  def load_spots_by_date
    Spot.where(date: start_date..end_date)
        .currency_exists(currency)
        .order(:date)
        .group_by(&:date)
  end

  def load_hong_baos_by_date
    saved_hong_baos
      .where.not(gifted_at: nil)
      .group_by { |hb| hb.gifted_at.to_date }
  end

  def build_btc_price_series(shared_data)
    Series::BitcoinPrice.new(
      saved_hong_baos,
      start_date: start_date,
      end_date: end_date,
      currency: currency,
      shared_data: shared_data
    ).call
  end

  def build_btc_price_with_markers_series(shared_data)
    Series::BitcoinPriceWithMarkers::SavedHongBao.new(
      saved_hong_baos,
      start_date: start_date,
      end_date: end_date,
      currency: currency,
      shared_data: shared_data
    ).call
  end

  def build_portfolio_series(shared_data)
    Series::Portfolio.new(
      saved_hong_baos,
      start_date: start_date,
      end_date: end_date,
      currency: currency,
      shared_data: shared_data
    ).call
  end

  def build_net_deposits_series(shared_data)
    Series::NetDeposit.new(
      saved_hong_baos,
      start_date: start_date,
      end_date: end_date,
      currency: currency,
      shared_data: shared_data
    ).call
  end

  def build_hong_bao_markers_series(shared_data)
    Series::SavedHongBao.new(
      saved_hong_baos,
      start_date: start_date,
      end_date: end_date,
      currency: currency,
      shared_data: shared_data
    ).call
  end
end
