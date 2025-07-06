module Dock
  class ItemComponent < ApplicationComponent
    def initialize(label:, icon:, href:, **options)
      @label = label
      @icon = icon
      @href = href
      @options = options
    end

    def active?
      request.path == href
    end

    def active_class
      active? ? "dock-active" : ""
    end

    def options
      @options.merge(class: active_class)
    end

    attr_reader :label, :icon, :href
  end
end
