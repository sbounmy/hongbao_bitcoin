# frozen_string_literal: true

class SimulationsController < ApplicationController
  allow_unauthenticated_access
  layout "embed", only: :embed

  def new
    @simulation = Simulation.new
    @result = Simulations::Create.call(@simulation.to_service_params)
  end

  def embed
    @simulation = Simulation.new
    @result = Simulations::Create.call(@simulation.to_service_params)
    render :embed
  end

  def create
    @simulation = Simulation.new(simulation_params)
    stats_only = params[:stats_only] == "true"
    @result = Simulations::Create.call(@simulation.to_service_params.merge(stats_only:))
  end

  private

  def simulation_params
    # Build dynamic permit structure from EVENTS configuration
    events_permit = {}
    Simulation::EVENTS.each_key do |event_key|
      # Birthday has additional fields for month and day
      events_permit[event_key] = event_key == :birthday ? [ :amount, :month, :day ] : [ :amount ]
    end

    params.require(:simulation).permit(
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
