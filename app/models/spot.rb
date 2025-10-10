class Spot < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  CURRENCIES = %i[usd eur].freeze

  scope :currency_exists, ->(currency) { where("json_extract(prices, '$.#{currency}') IS NOT NULL") }
  scope :current, ->(currency) { order(date: :desc).where("json_extract(prices, '$.#{currency}') IS NOT NULL").first }
  store_accessor :prices, *CURRENCIES

  def to(currency)
    currency = currency.to_sym.downcase
    raise ArgumentError, "Unsupported currency: #{currency}" unless CURRENCIES.include?(currency)

    fetch_price(currency)
  end
end
