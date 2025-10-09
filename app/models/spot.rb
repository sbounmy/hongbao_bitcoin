class Spot < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  COINBASE_BASE_URI = "https://api.coinbase.com/v2/prices"
  CACHE_EXPIRES_IN = 10.minutes
  HISTORICAL_CACHE_EXPIRES_IN = 24.hours
  SUPPORTED_CURRENCIES = %i[usd eur].freeze

  store_accessor :prices, *SUPPORTED_CURRENCIES

  # def initialize(date: nil)
  #   @date = date.try(:utc)
  # end

  def self.current(currency)
    new.to(currency)
  end

  def to(currency)
    currency = currency.to_sym.downcase
    raise ArgumentError, "Unsupported currency: #{currency}" unless SUPPORTED_CURRENCIES.include?(currency)

    fetch_price(currency)
  end
end
