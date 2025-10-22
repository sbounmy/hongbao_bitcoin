class Spot < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  CURRENCIES = %i[usd eur].freeze

  scope :currency_exists, lambda { |currency|
    currency_sym = validate_and_normalize_currency!(currency)
    where("json_extract(prices, '$.#{currency_sym}') IS NOT NULL")
  }

  store_accessor :prices, *CURRENCIES

  def self.current(currency)
    Rails.cache.fetch("current_#{currency}", expires_in: 3.minutes) do
      currency_sym = validate_and_normalize_currency!(currency)
      order(date: :desc).where("json_extract(prices, '$.#{currency_sym}') IS NOT NULL").first
    end
  end

  private

  def self.validate_and_normalize_currency!(currency)
    currency_sym = currency.to_s.downcase.to_sym
    raise ArgumentError, "Unsupported currency: #{currency}" unless CURRENCIES.include?(currency_sym)
    currency_sym
  end
end
