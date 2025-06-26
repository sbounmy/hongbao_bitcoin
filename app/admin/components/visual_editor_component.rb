# frozen_string_literal: true

module Admin
  class VisualEditorComponent < ApplicationComponent
    attr_reader :form, :object

    def initialize(form:, input_base_name:)
      @form = form
      @object = form.object
      @input_base_name = input_base_name
      super()
    end

    delegate :image_back, :image_front, to: :object

    def elements_by_view
      common = common_elements
      if object.is_a?(Input::Theme)
        {
          "front" => [ "public_address_qrcode", "public_address_text", "app_public_address_qrcode" ] & common,
          "back" => [ "private_key_qrcode", "private_key_text", "mnemonic_text" ] & common
        }
      elsif object.is_a?(Paper)
        {
          "front" => object.front_elements.keys.map(&:to_s) & common,
          "back" => object.back_elements.keys.map(&:to_s) & common
        }
      end
    end

    def all_ai_element_types
      common_elements
    end

    def all_ai_element_properties
      Input::Theme::AI_ELEMENT_PROPERTIES & Paper::ELEMENT_ATTRIBUTES.map(&:to_s)
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

    def preview_text(element_type)
      case element_type
      when "private_key_text"
        "private-key-text-56fz9e415s6f654e654rz4fe64zef49z8e4f"
      when "public_address_text"
        "public-address-56fz9e415s6f654e654rz465fe64ezfze65ff5"
      when "mnemonic_text"
        "beautiful dog great cat happy fish wonderful bird amazing turtle fantastic rabbit marvelous horse astonishing cow flabbergasted sheep incredible pig lazy chicken awesome"
      else
        "Preview Text"
      end
    end

    def hidden_input_value(element_type, property)
      source_hash = object.is_a?(Input::Theme) ? object.ai : object.elements
      default_hash = Input::Theme.default_ai_elements
      source_hash&.dig(element_type, property.to_s) || default_hash.dig(element_type, property.to_s)
    end

    private

    def common_elements
      Input::Theme::AI_ELEMENT_TYPES & Paper::ELEMENTS
    end

    def element_data(element_type)
      source_hash = object.is_a?(Input::Theme) ? object.ai : object.elements
      default_hash = Input::Theme.default_ai_elements
      (source_hash || {}).fetch(element_type, default_hash.fetch(element_type, {}))
    end
  end
end
