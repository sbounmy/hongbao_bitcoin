module CalendarDateParsing
  extend ActiveSupport::Concern

  private

  def parse_calendar_date
    if params[:month_year].present?
      # Parse formats like "july", "july-2024", "december-2025"
      parts = params[:month_year].downcase.split("-")
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
    elsif params[:date].present?
      # Fallback to old format for backwards compatibility
      Date.parse(params[:date])
    else
      Date.current
    end
  rescue ArgumentError
    Date.current
  end
end