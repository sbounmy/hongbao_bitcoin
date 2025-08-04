module InputEvents
  class Index
    def self.call(params:)
      new(params: params).call
    end

    def initialize(params:)
      @params = params
      @type = params[:type] || "calendar"
      @month_year = params[:month]
      @tag_ids = Array(params[:tags]).map(&:to_i).reject(&:zero?)
    end

    def call
      Result.new(
        events: events,
        month_events: month_events,
        events_by_day: events_by_day,
        date: date,
        type: @type,
        selected_tag_ids: @tag_ids,
        all_tags: event_tags
      )
    end

    private

    attr_reader :params, :type, :month_year, :tag_ids

    def date
      @date ||= parse_calendar_date
    end

    def events
      @events ||= begin
        scope = Input::Event.all
        scope = scope.with_any_tag_ids(*tag_ids) if tag_ids.present?
        scope
      end
    end

    def event_tags
      @event_tags ||= Tag.for_category("input_events")
    end

    def month_events
      @month_events ||= begin
        start_date = date.beginning_of_month
        end_date = date.end_of_month

        events.select do |event|
          if event.date
            anniversary = event.anniversary(date.beginning_of_month)
            anniversary >= start_date && anniversary <= end_date
          end
        end
      end.sort_by { |e| e.anniversary(date.beginning_of_month) }
    end

    def events_by_day
      @events_by_day ||= begin
        grouped = {}
        month_events.each do |event|
          day = event.anniversary(date.beginning_of_month)
          grouped[day] ||= []
          grouped[day] << event
        end
        grouped
      end
    end

    def parse_calendar_date
      if month_year.present?
        # Parse formats like "july", "july-2024", "december-2025"
        parts = month_year.downcase.split("-")
        month_name = parts[0]
        year = parts[1]&.to_i || Date.current.year

        # Convert month name to month number
        month_index = Date::MONTHNAMES.compact.map(&:downcase).index(month_name) ||
                      Date::ABBR_MONTHNAMES.compact.map(&:downcase).index(month_name)

        if month_index
          month_number = month_index + 1  # Arrays are 0-indexed, months are 1-indexed
          Date.new(year, month_number, 1)
        else
          Date.current
        end
      else
        Date.current
      end
    rescue ArgumentError
      Date.current
    end

    class Result
      attr_reader :events, :month_events, :events_by_day, :date, :type, :selected_tag_ids, :all_tags

      def initialize(events:, month_events:, events_by_day:, date:, type:, selected_tag_ids:, all_tags:)
        @events = events
        @month_events = month_events
        @events_by_day = events_by_day
        @date = date
        @type = type
        @selected_tag_ids = selected_tag_ids
        @all_tags = all_tags
      end

      def calendar?
        type == "calendar"
      end

      def agenda?
        type == "agenda"
      end
    end
  end
end
