# frozen_string_literal: true

module Series
  class Base
    attr_reader :saved_hong_baos, :start_date, :end_date, :currency

    def initialize(saved_hong_baos, start_date:, end_date:, currency:, shared_data: {})
      @saved_hong_baos = saved_hong_baos
      @start_date = start_date
      @end_date = end_date
      @currency = currency
      @shared_data = shared_data
    end

    def call
      raise NotImplementedError, "Subclasses must implement the call method"
    end

    protected

    # Shared data accessors - allows sharing pre-loaded data between series
    def spots_by_date
      @shared_data[:spots_by_date] ||= load_spots_by_date
    end

    def hong_baos_by_date
      @shared_data[:hong_baos_by_date] ||= load_hong_baos_by_date
    end

    def current_btc_price
      @shared_data[:current_btc_price] ||= Spot.current(currency)&.prices&.dig(currency.to_s).to_f
    end

    private

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

    def date_range
      @date_range ||= (start_date..end_date)
    end

    def timestamp_for(date)
      date.to_time.to_i * 1000
    end
  end
end
