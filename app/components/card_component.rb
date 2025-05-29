class CardComponent < ApplicationComponent
  renders_one :back, ->(options = {}) { CardBackComponent.new(options) }
  renders_one :front, ->(options = {}) do
    CardFrontComponent.new(options)
  end

  attr_reader :options

  def initialize(options = {})
    @options = options
  end

  def action
    clickable? ? "click->reveal#toggle" : nil
  end

  def clickable?
    back? && @options.fetch(:clickable, true)
  end

  class CardBodyComponent < ApplicationComponent
    attr_reader :options

    def initialize(options = {})
      @options = options
    end
  end

  class CardFrontComponent < CardBodyComponent
  end

  class CardBackComponent < CardBodyComponent
  end
end
