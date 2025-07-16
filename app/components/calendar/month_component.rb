module Calendar
  class MonthComponent < ApplicationComponent
    attr_reader :date, :prev_link, :next_link

    def initialize(date:, prev_link:, next_link:)
      @date = date
      @prev_link = prev_link
      @next_link = next_link
    end

    def month_year
      date.strftime('%B %Y')
    end
  end
end