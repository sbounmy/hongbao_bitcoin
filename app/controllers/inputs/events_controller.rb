module Inputs
  class EventsController < ApplicationController
    allow_unauthenticated_access
    layout "main"

    def index
      result = InputEvents::Index.call(params: params)

      @date = result.date
      @events = result.events
      @month_events = result.month_events
      @events_by_day = result.events_by_day
      @selected_tag_ids = result.selected_tag_ids
      @all_tags = result.all_tags

      if result.calendar?
        render "calendar"
      else
        render "agenda"
      end
    end
  end
end
