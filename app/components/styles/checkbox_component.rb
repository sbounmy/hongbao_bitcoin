module Styles
  class CheckboxComponent < ViewComponent::Base
    def initialize(checkbox:, form:, checkbox_iteration:)
      @checkbox = checkbox
      @form = form
      @iteration = checkbox_iteration
    end

    private

    attr_reader :checkbox, :form
  end
end
