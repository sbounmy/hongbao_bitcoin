# frozen_string_literal: true

module Ui
  class RatingComponent < ApplicationComponent
    renders_one :avatar

    def initialize(rate:, text: nil, **options)
      @rate = rate.to_i.clamp(0, 5)
      @text = text
      @options = options
    end

    private

    attr_reader :rate, :text, :options

    def component_classes
      classes = [ "flex flex-col items-center p-8" ]
      classes << options[:class] if options[:class]
      classes.compact.join(" ")
    end

    def stars
      (1..5).map do |i|
        if i <= rate
          "★"
        else
          "☆"
        end
      end
    end
  end
end
