# frozen_string_literal: true

class Input::Event < Input
  self.renderable = true

  metadata :date, :description, :price_usd, :fixed_day

  validates :date, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :price_usd, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  def papers
    Paper.with_any_input_ids(id)
  end

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

  def fixed_day?
    fixed_day == true || fixed_day == "true" || fixed_day == "1"
  end

  def variable_date?
    !fixed_day?
  end

  # Set default for new records
  after_initialize do
    if new_record? && fixed_day.nil?
      self.fixed_day = true
    end
  end
end
