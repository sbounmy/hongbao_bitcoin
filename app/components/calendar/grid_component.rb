module Calendar
  class GridComponent < ApplicationComponent
    renders_many :days, Calendar::DayComponent
    renders_one :month_header, Calendar::MonthComponent

    attr_reader :date, :events_by_day, :start_date, :end_date

    def initialize(date:, events_by_day: {})
      @date = date
      @events_by_day = events_by_day
      @start_date = date.beginning_of_month.beginning_of_week(:sunday)
      @end_date = date.end_of_month.end_of_week(:sunday)
    end

    def day_names
      %w[Sun Mon Tue Wed Thu Fri Sat]
    end

    def weeks
      @start_date.step(@end_date, 7).to_a
    end

    def days_in_week(week_start)
      (0..6).map { |i| week_start + i.days }
    end
  end
end
