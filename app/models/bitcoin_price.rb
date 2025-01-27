class BitcoinPrice < ApplicationRecord
  validates :date, presence: true, uniqueness: { scope: :currency }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR] }

  attr_accessor :birthdate, :birthday_amount, :christmas_amount, :cny_amount

  def birthdate_price_btc(birthdate)
    birth_date = birthdate.to_date
    current_date = Date.current

    prices = BitcoinPrice
      .where("strftime('%m', date) = ? AND strftime('%d', date) = ?",
             birth_date.strftime("%m"), birth_date.strftime("%d"))
      .where("date >= ? AND date <= ?", birth_date, current_date)
      .order(date: :asc)
    sum = 0
    prices.each do |price_record|
      puts price_record.inspect
      puts (birthday_amount.to_f / price_record.price).round(4)
      sum += (birthday_amount.to_f / price_record.price).round(4)
    end
    sum
  end

  def christmas_price_btc(birthdate)
    christmas_price = BitcoinPrice
      .where("strftime('%m', date) = '12' AND strftime('%d', date) = '25'")
      .where("date >= ?", birthdate)
      .order(date: :asc)
    sum = 0
    christmas_price.each do |price_record|
      puts price_record.inspect
      puts (christmas_amount.to_f / price_record.price).round(4)
      sum += (christmas_amount.to_f / price_record.price).round(4)
    end
    sum
  end

  def lunar_new_year_price_btc(birthdate)
    lunar_new_year_price = BitcoinPrice
      .where("date >= ?", birthdate)
      .where("strftime('%m', date) = '02' AND strftime('%d', date) = '01'")
      .order(date: :asc)
    sum = 0
    lunar_new_year_price.each do |price_record|
      puts price_record.inspect
      puts (cny_amount.to_f / price_record.price).round(4)
      sum += (cny_amount.to_f / price_record.price).round(4)
    end
    sum
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
      christmas_total: calculate_gift_total(age, christmas_amount),
      cny_total: calculate_gift_total(age, cny_amount),
      total_btc: total_btc[:btc],
      total_btc_to_usd: total_btc[:usd]
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

  def total_btc
    btc_amount = birthdate_price_btc(birthdate) + christmas_price_btc(birthdate) + lunar_new_year_price_btc(birthdate)
    current_price = BitcoinPriceFetcher.fetch_current_price

    {
      btc: btc_amount.round(8),
      usd: (btc_amount * current_price).round(2)
    }
  end
end
