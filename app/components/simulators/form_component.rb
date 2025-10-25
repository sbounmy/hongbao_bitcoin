# frozen_string_literal: true

module Simulators
  class FormComponent < ApplicationComponent
    def initialize(simulator:)
      @simulator = simulator
    end

    private

    attr_reader :simulator

    def event_configs
      Simulator::EVENTS
    end

    def month_options
      Date::MONTHNAMES.compact.each_with_index.map { |name, index| [ name, index + 1 ] }
    end

    def day_options
      (1..31).map { |day| [ day.to_s.rjust(2, "0"), day ] }
    end

    def event_amount(event_key)
      simulator.events_attributes.dig(event_key.to_s, :amount) ||
        Simulator::EVENTS[event_key][:default_amount]
    end

    def event_month(event_key)
      return nil unless event_key == :birthday
      simulator.events_attributes.dig("birthday", :month) ||
        Simulator::DEFAULT_BIRTHDAY[:month]
    end

    def event_day(event_key)
      return nil unless event_key == :birthday
      simulator.events_attributes.dig("birthday", :day) ||
        Simulator::DEFAULT_BIRTHDAY[:day]
    end
  end
end
