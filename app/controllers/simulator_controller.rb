# frozen_string_literal: true

class SimulatorController < ApplicationController
  allow_unauthenticated_access

  def index
    @simulator = Simulator.new
    @result = Simulators::Create.call(@simulator.to_service_params)
  end

  def calculate
    @simulator = Simulator.new(simulator_params)
    @result = Simulators::Create.call(@simulator.to_service_params)
  end

  private

  def simulator_params
    # Build dynamic permit structure from EVENTS configuration
    events_permit = {}
    Simulator::EVENTS.each_key do |event_key|
      # Birthday has additional fields for month and day
      events_permit[event_key] = event_key == :birthday ? [ :amount, :month, :day ] : [ :amount ]
    end

    params.require(:simulator).permit(
      :years,
      events_attributes: events_permit
    ).tap do |attrs|
      # Convert events_attributes from ActionController::Parameters to regular hash
      if attrs[:events_attributes].present?
        attrs[:events_attributes] = attrs[:events_attributes].to_h
      end
    end
  end
end
