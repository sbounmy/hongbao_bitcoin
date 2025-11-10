# frozen_string_literal: true

class HongBaoPerformanceService
  def initialize(hong_bao, currency: :usd)
    @hong_bao = hong_bao
    @balance = hong_bao.balance
    @currency = currency
    @start_date = first_transaction_date
    @end_date = Date.today
  end

  def call
    preload_shared_data

    {
      btc_price: build_btc_price_series,
      hong_bao_value: build_hong_bao_value_series,
      metadata: build_metadata
    }
  end

  private

  def preload_shared_data
    @shared_data = {
      spots_by_date: Spot.where(date: @start_date..@end_date)
                         .currency_exists(@currency)
                         .order(:date)
                         .group_by(&:date)
    }
  end

  # Create duck-typed object that Portfolio series can work with
  def adaptee
    @adaptee ||= begin
      btc_amount_sats = (@balance.btc * 100_000_000).to_i
      spot_buy = Spot.find_by(date: first_transaction_date)

      OpenStruct.new(
        initial_sats: btc_amount_sats,
        current_sats: btc_amount_sats, # Assume no changes for now
        spot_buy: spot_buy,
        gifted_at: first_transaction_date.to_time
      )
    end
  end

  def build_btc_price_series
    # REUSE: Series::BitcoinPrice
    Series::BitcoinPrice.new(
      [],  # BitcoinPrice doesn't use saved_hong_baos but Base requires it
      start_date: @start_date,
      end_date: @end_date,
      currency: @currency,
      shared_data: @shared_data
    ).call
  end

  def build_hong_bao_value_series
    # REUSE: Series::Portfolio with single hong bao!
    Series::Portfolio.new(
      [ adaptee ],  # Single element array
      start_date: @start_date,
      end_date: @end_date,
      currency: @currency,
      shared_data: @shared_data
    ).call
  end

  def first_transaction_date
    @first_transaction_date ||= begin
      first_tx = @balance.transactions.min_by { |t| t.timestamp || Date.today }
      first_tx&.timestamp&.to_date || Date.today
    end
  end

  def to_timestamp(date)
    date.to_time.to_i * 1000
  end

  def build_metadata
    spot_start = @shared_data[:spots_by_date][@start_date]&.first
    spot_end = @shared_data[:spots_by_date][@end_date]&.first

    original_price = spot_start&.prices&.dig(@currency.to_s)&.to_f || 0
    current_price = spot_end&.prices&.dig(@currency.to_s)&.to_f || 0

    original_value = @balance.btc * original_price
    current_value = @balance.btc * current_price
    gain_loss = current_value - original_value
    gain_loss_percent = original_value > 0 ? (gain_loss / original_value) * 100 : 0

    {
      original_value: original_value.round(2),
      current_value: current_value.round(2),
      gain_loss: gain_loss.round(2),
      gain_loss_percent: gain_loss_percent.round(2),
      gifted_date: first_transaction_date
    }
  end
end
