class ProgressBarComponent < ApplicationComponent
  attr_reader :value, :max, :color, :options

  def initialize(value: nil, max: "100", color: nil, **options)
    @value = value
    @max = max
    @color = color
    @options = options
  end

  def classes
    [
      "progress",
      color_class,
      options[:class]
    ].compact.join(" ")
  end

  private

  def color_class
    "progress-#{color}" if color.present?
  end
end
