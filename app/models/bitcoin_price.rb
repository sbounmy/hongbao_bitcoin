class BitcoinPrice < ApplicationRecord
  validates :date, presence: true, uniqueness: { scope: :currency }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR] }

  attr_accessor :birthday, :birthday_amount, :christmas_amount, :cny_amount

  def birthdate_price(birthdate)
    @birthdate_price ||= BitcoinPrice.where("date >= ?", birthdate).order(date: :asc)
  end

  def christmas_price(birthdate, christmas_date)
    @christmas_price ||= BitcoinPrice.where("date >= ? AND date = ?", birthdate, christmas_date).order(date: :asc)
  end

  def lunar_new_year_price(birthdate, lunar_new_year_date)
    @lunar_new_year_price ||= BitcoinPrice.where("date >= ? AND date = ?", birthdate, lunar_new_year_date).order(date: :asc)
  end

  def calculate_totals
    return nil unless birthday.present?

    birth_date = Date.parse(birthday)
    today = Date.current
    age = calculate_age(birth_date, today)

    return nil unless age.positive?

    {
      age: age,
      birthday_total: calculate_gift_total(age, birthday_amount),
      christmas_total: calculate_gift_total(age, christmas_amount),
      cny_total: calculate_gift_total(age, cny_amount),
      yearly_data: calculate_yearly_data(age)
    }
  end

  private

  def calculate_age(birth_date, today)
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

  def total_euros
    birthday_total + christmas_total + cny_total
  end

  def total_btc
    total_euros / current_btc_price
  end
end
