module Variants
  class DescriptionComponent < ApplicationComponent
    def initialize(variant:)
      @variant = variant
    end

    private

    attr_reader :variant

    def color_option_values
      @color_option_values ||= variant.color_option_values
    end

    def envelopes_per_color
      return 0 unless color_option_values.any?

      total_envelopes = variant.envelopes_count || 0
      total_envelopes / color_option_values.size
    end

    def render?
      color_option_values.any?
    end
  end
end
