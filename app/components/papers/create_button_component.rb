module Papers
  class CreateButtonComponent < ApplicationComponent
    def initialize(form:)
      @form = form
    end

    def data_attributes
      {
        controller: "disabled",
        action: "preview:none@window->disabled#add preview:selected@window->disabled#remove",
        turbo_submits_with: "Processing...",
        disabled_target: "element"
      }
    end

    attr_reader :form
  end
end
