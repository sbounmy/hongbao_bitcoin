class ProgressBarComponent < ApplicationComponent
  attr_reader :value, :max, :color, :animated, :duration, :options

  def initialize(value: nil, max: "100", color: nil, animated: false, duration: 60, **options)
    @value = value
    @max = max
    @color = color
    @animated = animated
    @duration = duration
    @options = options
  end

  def classes
    [
      "progress",
      color_class,
      options[:class]
    ].compact.join(" ")
  end

  def animated?
    @animated
  end

  private

  def color_class
    "progress-#{color}" if color.present?
  end
end
