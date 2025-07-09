module Papers
  class CreateButtonComponent < ApplicationComponent
    def initialize(form:)
      @form = form
    end

    def data_attributes
      {
        controller: "disabled",
        action: "preview:none@window->disabled#add preview:selected@window->disabled#remove click->toggle#switch",
        toggle_hide_param: "#form-column",
        toggle_show_param: "#preview-column",
        turbo_submits_with: "Processing...",
        disabled_target: "element"
      }
    end

    def data_attributes_desktop
      data_attributes.except(
        :toggle_hide_param,
        :toggle_show_param,
      )
    end

    attr_reader :form
  end
end