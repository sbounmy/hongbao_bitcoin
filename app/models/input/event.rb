# frozen_string_literal: true

class Input::Event < Input
  store :metadata, accessors: [:date]

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
end
