class Spot < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  CURRENCIES = %i[usd eur].freeze

  scope :currency_exists, ->(currency) { where("json_extract(prices, '$.#{currency}') IS NOT NULL") }
  store_accessor :prices, *CURRENCIES

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
