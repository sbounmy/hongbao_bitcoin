# frozen_string_literal: true

module Admin
  class VisualEditorComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      @theme = form.object
      super
    end

    def elements_by_view
      {
        "front" => [ "public_address_qrcode", "public_address_text", "app_public_address_qrcode" ],
        "back" => [ "private_key_qrcode", "private_key_text", "mnemonic_text" ]
      }
    end

    def element_color(element_type)
      element_data(element_type)["color"] || "black"
    end

    def element_hidden_class(view)
      view != "front" ? "hidden" : ""
    end

    def is_qr?(element_type)
      element_type.include?("qrcode")
    end

    def all_ai_element_types
      Input::Theme::AI_ELEMENT_TYPES
    end

    def all_ai_element_properties
      Input::Theme::AI_ELEMENT_PROPERTIES
    end

    def hidden_input_value(element_type, property)
      @theme.ai&.dig(element_type, property.to_s) || Input::Theme.default_ai_elements.dig(element_type, property.to_s)
    end

    private

    def element_data(element_type)
      (@theme.ai || {}).fetch(element_type, Input::Theme.default_ai_elements[element_type] || {})
    end

    attr_reader :form, :theme
  end
end
