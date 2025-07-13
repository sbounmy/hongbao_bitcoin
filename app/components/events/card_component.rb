# frozen_string_literal: true

module Events
  class CardComponent < ApplicationComponent
    with_collection_parameter :event
    attr_reader :event

    def initialize(event:)
      @event = event
      super
    end

    private

    # Use the most recent paper associated with the event for display info
    def cover_paper
      return nil
      @cover_paper ||= event.papers.order(created_at: :desc).first
    end

    def image_url
      return unless event&.image&.attached?
      url_for(event.image)
    end

    def event_date
      # The date is stored in the metadata hash via store_accessor.
      # It might be a string, so we ensure it's a Date object.
      event.date
    end

    def event_day
      event_date.strftime("%d")
    end

    def event_month
      event_date.strftime("%b").upcase
    end

    def event_year
      event_date.strftime("%Y")
    end
  end
end
