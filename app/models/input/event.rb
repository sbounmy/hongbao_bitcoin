# frozen_string_literal: true

class Input::Event < Input
  self.renderable = true

  store :metadata, accessors: [ :date, :description, :price_usd ]

  # Doing this in ruby because date is stored as a string in a jsonb column.
  # We won't have millions of events, so it's not a big deal.
  def self.find_by_anniversary(today = Date.today)
    all.sort_by { |event| event.anniversary(today) }
  end

  def anniversary(today = Date.today)
    anniversary_this_year = date.change(year: today.year)

    if anniversary_this_year < today
      anniversary_this_year.next_year
    else
      anniversary_this_year
    end
  end

  def date
    Date.parse(super)
  end

  def age
    Date.today.year - date.year
  end
end
