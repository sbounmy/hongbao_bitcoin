class InputsController < ApplicationController
  allow_unauthenticated_access
  layout "main"

  def calendar
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @events = Input::Event.all

    # Get events for the current month
    start_date = @date.beginning_of_month
    end_date = @date.end_of_month

    @month_events = @events.select do |event|
      if event.date
        anniversary = event.anniversary(@date)
        anniversary >= start_date && anniversary <= end_date
      end
    end.sort_by { |e| e.anniversary(@date) }

    # Get all event dates for marking the calendar
    @event_dates = @events.map do |event|
      event.anniversary(@date) if event.date
    end.compact
  end

  def show
    @input = Input.find(params[:id])
    @papers = Paper.with_all_input_ids(@input.id).order(created_at: :desc)

    if @input.renderable
      render "inputs/#{@input.type.split("::").last.downcase.pluralize}/show"
    else
      render plain: "Not found", status: :not_found
    end
  end
end
