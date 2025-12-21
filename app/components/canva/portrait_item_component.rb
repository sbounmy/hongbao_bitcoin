# frozen_string_literal: true

module Canva
  class PortraitItemComponent < ItemComponent
    DEFAULT_PLACEHOLDER = "portrait-placeholder.svg"

    def initialize(name:, item:, placeholder: nil)
      super(name:, item:)
      @placeholder = placeholder
    end

    private

    def placeholder
      @placeholder || ActionController::Base.helpers.asset_path(DEFAULT_PLACEHOLDER)
    end

    def controller_name
      "portrait-item"
    end

    def portrait_data
      {
        "#{data_prefix}_placeholder_value": placeholder
      }.compact
    end

    def event_actions
      "preview:selected@window->portrait-item#handleSelected " \
      "portrait:loading@window->portrait-item#handleLoading " \
      "portrait:changed@window->portrait-item#handleChanged"
    end
  end
end
