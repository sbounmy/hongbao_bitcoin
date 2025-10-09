class SpotsImportJob < ApplicationJob
  queue_as :default

  COINBASE_BASE_URI = "https://api.coinbase.com/v2/prices"
  START_DATE = Date.new(2013, 9, 1) # Bitcoin started getting tracked around this time
  REQUEST_DELAY = 0.2 # seconds between requests to avoid rate limiting

  attr_reader :currency

  def start_date
    Spot.where(prices: { currency => nil }).order(date: :desc).first&.date || START_DATE
  end

  def symbol
    "BTC-#{currency.upcase}"
  end

  def initialize(currency: :usd)
    @currency = currency
  end

  def perform
    date = start_date
    while date < Date.today
      fetch_price(date)
      date += 1.day
      sleep REQUEST_DELAY
    end
  end

  private

  def fetch_price(date)
    uri = URI("#{COINBASE_BASE_URI}/#{symbol}/spot?date=#{date.strftime('%Y-%m-%d')}")
    Rails.logger.info(uri)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    Rails.logger.info("Fetched price #{date}: #{data.inspect}")
    price = data.dig("data", "amount")&.to_f
    Spot.find_or_initialize_by(date:).tap do |spot|
      spot.prices[currency] = price
      spot.save!
      Rails.logger.info("Imported price #{date}: #{price} #{currency.upcase} #{spot.inspect}")
    end
  end
end
