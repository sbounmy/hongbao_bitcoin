module Calendar
  class DayComponent < ApplicationComponent
    attr_reader :day, :events, :current_month

    def initialize(day:, events: [], current_month:)
      @day = day
      @events = events
      @current_month = current_month
    end

    def is_current_month?
      day.month == current_month
    end

    def is_today?
      day == Date.current
    end

    def border_classes
      if is_today?
        "border-orange-500 border-2"
      else
        "border-base-300"
      end
    end

    def opacity_class
      is_current_month? ? "" : "opacity-40"
    end

    def day_number_color
      if is_today?
        "text-orange-500"
      elsif !is_current_month?
        "text-base-content/50"
      else
        "text-base-content"
      end
    end

    def text_color_for_event(event)
      event.image.attached? ? "text-white" : "text-orange-700"
    end

    def price_color_for_event(event)
      event.image.attached? ? "text-white/80" : "text-base-content/60"
    end
  end
end
