module SavedHongBaos
  class StatsComponent < ApplicationComponent
    def initialize(saved_hong_baos:)
      @saved_hong_baos = saved_hong_baos
    end

    private

    attr_reader :saved_hong_baos

    def total_count
      saved_hong_baos.count
    end

    def total_balance_btc
      saved_hong_baos.sum(&:btc)
    end

    def total_balance_usd
      saved_hong_baos.sum(&:usd)
    end
  end
end
