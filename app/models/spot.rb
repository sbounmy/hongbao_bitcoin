class Spot < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  CURRENCIES = %i[usd eur].freeze

  scope :currency_exists, lambda { |currency|
    currency_sym = validate_and_normalize_currency!(currency)
    where("json_extract(prices, '$.#{currency_sym}') IS NOT NULL")
  }

  scope :current, lambda { |currency|
    currency_sym = validate_and_normalize_currency!(currency)
    order(date: :desc).where("json_extract(prices, '$.#{currency_sym}') IS NOT NULL").first
  }

  store_accessor :prices, *CURRENCIES

  private

  def self.validate_and_normalize_currency!(currency)
    currency_sym = currency.to_s.downcase.to_sym
    raise ArgumentError, "Unsupported currency: #{currency}" unless CURRENCIES.include?(currency_sym)
    currency_sym
  end
end
