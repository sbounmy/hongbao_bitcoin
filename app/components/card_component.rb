class CardComponent < ApplicationComponent
  renders_one :back, "CardBackComponent"
  renders_one :front, "CardFrontComponent"

  attr_reader :options

  def initialize(options = {})
    @options = options
  end

  def action
    @options.fetch(:clickable, true) ? "click->reveal#toggle" : nil
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
