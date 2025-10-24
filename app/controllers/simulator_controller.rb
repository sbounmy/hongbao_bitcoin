# frozen_string_literal: true

class SimulatorController < ApplicationController
  allow_unauthenticated_access

  def index
    # Default values for the form
    @years = 5
  end

  def calculate
    @simulator_service = BitcoinGiftingSimulatorService.new(simulator_params)
    result = @simulator_service.call

    @event_hong_baos = result[:event_hong_baos]
    @chart_data = result[:chart_data]

    Rails.logger.debug "Simulator params: #{simulator_params.inspect}"
    Rails.logger.debug "Events: #{simulator_params[:events]&.inspect}"
    Rails.logger.debug "Event amounts: #{simulator_params[:event_amounts]&.inspect}"
    Rails.logger.debug "Result count: #{@event_hong_baos&.count}"

    # respond_to do |format|
    #   format.turbo_stream
    #   format.html { render :calculate }
    # end
  end

  private

  def simulator_params
    params.permit(
      :years,
      :birthday_month,
      :birthday_day,
      event_amounts: {}
    ).tap do |p|
      # Convert string values to appropriate types
      p[:years] = p[:years].to_i if p[:years].present?
      p[:birthday_month] = p[:birthday_month].to_i if p[:birthday_month].present?
      p[:birthday_day] = p[:birthday_day].to_i if p[:birthday_day].present?

      # Convert event amounts to floats and filter out zero values
      if p[:event_amounts].present?
        p[:event_amounts] = p[:event_amounts].transform_keys(&:to_sym).transform_values(&:to_f)
        # Remove zero-value events from event_amounts
        p[:event_amounts] = p[:event_amounts].select { |_key, value| value > 0 }
        # Build events array as symbols based on which amounts are greater than 0
        p[:events] = p[:event_amounts].keys.map(&:to_sym)
      else
        p[:events] = []
        p[:event_amounts] = {}
      end
    end
  end
end
