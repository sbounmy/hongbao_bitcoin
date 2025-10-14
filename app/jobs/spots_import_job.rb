# frozen_string_literal: true

# Imports daily prices from coindesk
# If seed is true, it will import all data from the beginning of the bitcoin history
# If seed is false, it will import the last 10 days of data
class SpotsImportJob < ApplicationJob
  queue_as :default

  COINDESK_BASE_URI = "https://min-api.cryptocompare.com/data/v2/histoday"

  attr_reader :currency, :seed

  def symbol
    "BTC-#{currency.upcase}"
  end

  def perform(currency = "usd", seed: false)
    @currency = currency.to_sym
    @seed = seed
    while prices = fetch_price_from_coindesk
      prices["Data"]["Data"].each do |price|
        Spot.find_or_initialize_by(date: Time.at(price["time"]).to_date).tap do |spot|
          spot.prices[currency] = price["close"]
          spot.save!
        end
      end
      # stops if not seed or if zero data from coindesk
      break if !seed || prices["Data"]["Data"].any? { |price| price["close"].zero? }
    end
  end

  def cursor_date
    if seed
      latest_spot&.date || Date.today
    else
      Date.today
    end
  end

  def latest_spot
    Spot.currency_exists(currency).order(date: :asc).first
  end

  def limit
    seed ? 2000 : 10
  end

  private

  def fetch_price_from_coindesk
    uri = URI("#{COINDESK_BASE_URI}?fsym=BTC&tsym=#{currency}&limit=#{limit}")
    uri.query += "&toTs=#{cursor_date.to_time(:utc).to_i}"
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end
