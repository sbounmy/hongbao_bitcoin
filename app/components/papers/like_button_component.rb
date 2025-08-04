# frozen_string_literal: true

module Papers
  class LikeButtonComponent < ApplicationComponent
    attr_reader :paper, :size, :show_count, :variant

    def initialize(paper:, size: :small, show_count: true, variant: :default)
      @paper = paper
      @size = size
      @show_count = show_count
      @variant = variant
      super
    end

    def render?
      paper.present?
    end

    private

    def icon_size
      case size
      when :small
        "w-4 h-4"
      when :medium
        "w-5 h-5"
      when :large
        "w-6 h-6"
      else
        "w-4 h-4"
      end
    end

    def button_classes
      base_classes = "flex items-center gap-1 transition-colors"

      color_classes = if variant == :light
        liked? ? "text-red-500" : "text-white hover:text-red-500"
      else
        liked? ? "text-red-500" : "hover:text-red-500"
      end

      "#{base_classes} #{color_classes}"
    end

    def liked?
      false # We can't determine this in broadcast context, default to unliked state
    end

    def likes_count
      paper.likes_count || 0
    end
  end
end
