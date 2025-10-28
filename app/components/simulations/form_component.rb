# frozen_string_literal: true

module Simulations
  class FormComponent < ApplicationComponent
    renders_one :results

    def initialize(simulation:, stats_only: false)
      @simulation = simulation
      @stats_only = stats_only
    end

    private

    attr_reader :simulation, :stats_only

    def event_configs
      Simulation::EVENTS
    end

    def month_options
      Date::MONTHNAMES.compact.each_with_index.map { |name, index| [ name, index + 1 ] }
    end

    def day_options
      (1..31).map { |day| [ day.to_s.rjust(2, "0"), day ] }
    end

    def event_amount(event_key)
      simulation.events_attributes.dig(event_key.to_s, :amount) ||
        Simulation::EVENTS[event_key][:default_amount]
    end

    def event_month(event_key)
      return nil unless event_key == :birthday
      simulation.events_attributes.dig("birthday", :month) ||
        Simulation::DEFAULT_BIRTHDAY[:month]
    end

    def event_day(event_key)
      return nil unless event_key == :birthday
      simulation.events_attributes.dig("birthday", :day) ||
        Simulation::DEFAULT_BIRTHDAY[:day]
    end
  end
end
