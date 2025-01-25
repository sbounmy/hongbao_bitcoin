require "net/http"
require "json"

class Spot
  include ActiveModel::Model

  COINBASE_BASE_URI = "https://api.coinbase.com/v2/prices"
  CACHE_EXPIRES_IN = 10.minutes
  HISTORICAL_CACHE_EXPIRES_IN = 24.hours
  SUPPORTED_CURRENCIES = %i[usd eur gbp jpy].freeze

  attr_accessor :date

  def initialize(date: nil)
    @date = date
  end

  def to(currency)
    currency = currency.to_sym.downcase
    raise ArgumentError, "Unsupported currency: #{currency}" unless SUPPORTED_CURRENCIES.include?(currency)

    fetch_price(currency)
  end

  private

  def fetch_price(currency)
    cache_key = build_cache_key(currency)
    cache_duration = date ? HISTORICAL_CACHE_EXPIRES_IN : CACHE_EXPIRES_IN

    Rails.cache.fetch(cache_key, expires_in: cache_duration) do
      response = Net::HTTP.get(build_uri(currency))
      JSON.parse(response).dig("data", "amount")&.to_f
    end
  rescue StandardError => e
    Rails.logger.error "Failed to fetch Coinbase #{price_type} price for #{currency}: #{e.message}"
    nil
  end

  def build_uri(currency)
    base_path = "BTC-#{currency.upcase}/spot"
    query = date ? "?date=#{date.strftime('%Y-%m-%d')}" : ""
    URI("#{COINBASE_BASE_URI}/#{base_path}#{query}")
  end

  def build_cache_key(currency)
    parts = [ "coinbase_btc", currency ]
    parts << "historical" << date.strftime("%Y-%m-%d") if date
    parts.join("_")
  end

  def price_type
    date ? "historical" : "current"
  end
end
