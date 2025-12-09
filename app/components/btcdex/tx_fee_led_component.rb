# frozen_string_literal: true

module Btcdex
  class TxFeeLedComponent < ApplicationComponent
    include ActionView::Helpers::NumberHelper

    private

    def current_fee
      @current_fee ||= TransactionFee.current
    end

    def fee_satoshis
      current_fee&.priorities&.dig("hour") || 0
    end

    def fee_usd
      return 0 unless current_fee && spot

      # Calculate fee for typical 250 byte transaction
      total_satoshis = fee_satoshis * 250
      btc_amount = total_satoshis.to_f / 100_000_000
      (btc_amount * spot.usd.to_f).round(2)
    end

    def spot
      @spot ||= Spot.current(:usd)
    end

    def formatted_fee
      fee = fee_usd
      fee < 1 ? "$#{(fee * 100).round}¢" : "$#{fee.round(2)}"
    end

    def fee_level
      sats = fee_satoshis
      if sats <= 5
        :low
      elsif sats <= 20
        :medium
      else
        :high
      end
    end

  end
end
