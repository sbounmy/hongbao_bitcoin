class BitcoinPrice < ApplicationRecord
  validates :date, presence: true, uniqueness: { scope: :currency }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR] }

  attr_accessor :birthdate, :birthday_amount, :christmas_amount, :cny_amount

  def birthdate_price(birthdate)
    birth_date = birthdate.to_date
    current_date = Date.current

    prices = BitcoinPrice
      .where("strftime('%m', date) = ? AND strftime('%d', date) = ?",
             birth_date.strftime("%m"), birth_date.strftime("%d"))
      .where("date >= ? AND date <= ?", birth_date, current_date)
      .order(date: :asc)
    puts prices.inspect
    # Convert each birthday amount to BTC using historical prices and sum
    prices.sum do |price_record|
      puts price_record.inspect
      (birthday_amount.to_f / price_record.price).round(2)
    end
  end

  def christmas_price(birthdate, christmas_date)
    @christmas_price ||= BitcoinPrice
      .where("EXTRACT(MONTH FROM date) = 12 AND EXTRACT(DAY FROM date) = 25")
      .where("date >= ?", birthdate)
      .order(date: :asc)
  end

  def lunar_new_year_price(birthdate)
    @lunar_new_year_price ||= BitcoinPrice
      .where("date >= ?", birthdate)
      .where("EXTRACT(MONTH FROM date) = 2 AND EXTRACT(DAY FROM date) = 1")
      .order(date: :asc)
  end

  def calculate_totals
    return nil unless birthdate.present?

    # birth_date = Date.parse(birthdate)
    today = Date.current
    age = calculate_age(birthdate, today)

    return nil unless age.positive?

    {
      age: age,
      birthday_total: calculate_gift_total(age, birthday_amount),
      birthday_calc: calculate_gift_calc(age, birthday_amount),
      christmas_total: calculate_gift_total(age, christmas_amount),
      christmas_calc: calculate_gift_calc(age, christmas_amount),
      cny_total: calculate_gift_total(age, cny_amount),
      cny_calc: calculate_gift_calc(age, cny_amount),
      yearly_data: calculate_yearly_data(age)
    }
  end

  private

  def calculate_age(birth_date, today)
    birth_date = birth_date.to_date
    age = today.year - birth_date.year
    if today.month < birth_date.month ||
       (today.month == birth_date.month && today.day < birth_date.day)
      age -= 1
    end
    age
  end

  def calculate_gift_total(age, amount)
    (amount.to_f * age).round(2)
  end

  def calculate_gift_calc(age, amount)
    (amount.to_f * age).round(2)
  end

  def calculate_yearly_data(age)
    current_price = BitcoinPrice.where(currency: "EUR")
                              .order(date: :desc)
                              .first&.price || 43000

    yearly_data = []
    (1..age).each do |year|
      yearly_total = (birthday_amount.to_f + christmas_amount.to_f + cny_amount.to_f) * year
      yearly_data << {
        year: year,
        euros: yearly_total.round(2),
        btc: (yearly_total / current_price).round(8)
      }
    end
    yearly_data
  end

  def total_dollars
    birthday_total + christmas_total + cny_total
  end

  def total_btc
    total_dollars / current_btc_price
  end
end
