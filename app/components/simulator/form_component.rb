# frozen_string_literal: true

module Simulator
  class FormComponent < ApplicationComponent
    def initialize(years: 5, birthday_month: nil, birthday_day: nil)
      @years = years
      # Default to Satoshi Nakamoto's birthday (April 5th)
      @birthday_month = birthday_month || 4
      @birthday_day = birthday_day || 5
    end

    private

    attr_reader :years, :birthday_month, :birthday_day

    def event_options
      [
        { key: :christmas, label: "Christmas", emoji: "🎄", description: "December 25th", value: 50 },
        { key: :new_year, label: "New Year", emoji: "🎊", description: "January 1st", value: 0 },
        { key: :chinese_new_year, label: "Chinese New Year", emoji: "🧧", description: "Varies by year (lunar calendar)", value: 150 },
        { key: :birthday, label: "Birthday", emoji: "🎂", description: "Satoshi's Birthday (April 5th)", value: 100 }
      ]
    end

    def month_options
      Date::MONTHNAMES.compact.each_with_index.map { |name, index| [ name, index + 1 ] }
    end

    def day_options
      (1..31).map { |day| [ day.to_s.rjust(2, "0"), day ] }
    end
  end
end
