# frozen_string_literal: true

# Service to calculate Chinese New Year dates
# Based on lunar calendar calculations
class ChineseNewYearService
  # Pre-calculated Chinese New Year dates for performance
  # These are accurate dates from astronomical calculations
  CNY_DATES = {
    2005 => Date.new(2005, 2, 9),
    2006 => Date.new(2006, 1, 29),
    2007 => Date.new(2007, 2, 18),
    2008 => Date.new(2008, 2, 7),
    2009 => Date.new(2009, 1, 26),
    2010 => Date.new(2010, 2, 14),
    2011 => Date.new(2011, 2, 3),
    2012 => Date.new(2012, 1, 23),
    2013 => Date.new(2013, 2, 10),
    2014 => Date.new(2014, 1, 31),
    2015 => Date.new(2015, 2, 19),
    2016 => Date.new(2016, 2, 8),
    2017 => Date.new(2017, 1, 28),
    2018 => Date.new(2018, 2, 16),
    2019 => Date.new(2019, 2, 5),
    2020 => Date.new(2020, 1, 25),
    2021 => Date.new(2021, 2, 12),
    2022 => Date.new(2022, 2, 1),
    2023 => Date.new(2023, 1, 22),
    2024 => Date.new(2024, 2, 10),
    2025 => Date.new(2025, 1, 29),
    2026 => Date.new(2026, 2, 17),
    2027 => Date.new(2027, 2, 6),
    2028 => Date.new(2028, 1, 26),
    2029 => Date.new(2029, 2, 13),
    2030 => Date.new(2030, 2, 3),
    2031 => Date.new(2031, 1, 23),
    2032 => Date.new(2032, 2, 11),
    2033 => Date.new(2033, 1, 31),
    2034 => Date.new(2034, 2, 19),
    2035 => Date.new(2035, 2, 8),
    2036 => Date.new(2036, 1, 28),
    2037 => Date.new(2037, 2, 15),
    2038 => Date.new(2038, 2, 4),
    2039 => Date.new(2039, 1, 24),
    2040 => Date.new(2040, 2, 12),
    2041 => Date.new(2041, 2, 1),
    2042 => Date.new(2042, 1, 22),
    2043 => Date.new(2043, 2, 10),
    2044 => Date.new(2044, 1, 30),
    2045 => Date.new(2045, 2, 17)
  }.freeze

  class << self
    # Get Chinese New Year date for a specific year
    def for_year(year)
      return CNY_DATES[year] if CNY_DATES.key?(year)

      # For years outside our pre-calculated range, use approximation
      # Chinese New Year typically falls between January 21 and February 20
      # This is a simplified calculation for demonstration
      calculate_approximate_cny(year)
    end

    # Calculate all Chinese New Year dates within a year range
    def for_year_range(start_year, end_year)
      (start_year..end_year).map { |year| for_year(year) }
    end

    private

    # Simplified approximation for years outside our table
    # In production, you might want to use a more accurate lunar calendar library
    def calculate_approximate_cny(year)
      # Use modulo to find pattern - CNY repeats roughly every 19 years (Metonic cycle)
      base_year = 2024
      base_date = CNY_DATES[base_year]

      years_diff = year - base_year
      # Approximate: CNY moves ~11 days earlier each year, cycling back after ~33 days
      days_shift = (years_diff * -11) % 365

      # Start from base date and apply shift
      approximate_date = base_date + days_shift.days

      # Ensure it falls within valid CNY range (Jan 21 - Feb 20)
      if approximate_date.month == 12 || (approximate_date.month == 1 && approximate_date.day < 21)
        # Too early, push to late January
        Date.new(year, 1, 25)
      elsif approximate_date.month > 2 || (approximate_date.month == 2 && approximate_date.day > 20)
        # Too late, pull back to early February
        Date.new(year, 2, 10)
      else
        # Ensure the year is correct
        Date.new(year, approximate_date.month, approximate_date.day)
      end
    end
  end
end