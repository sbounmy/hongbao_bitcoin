module Styles
  class RadioComponent < ViewComponent::Base
    def initialize(radio:, form:, radio_iteration:)
      @radio = radio
      @form = form
      @iteration = radio_iteration
    end

    private

    attr_reader :radio, :form
  end
end
