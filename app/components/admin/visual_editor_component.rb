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
      if object.is_a?(Input::Theme)
        # For themes, include all AI element types (including portrait)
        {
          "front" => [ "portrait", "public_address_qrcode", "public_address_text" ],
          "back" => [ "private_key_qrcode", "private_key_text", "mnemonic_text" ]
        }
      elsif object.is_a?(Paper)
        # For papers, only include elements that exist in both AI_ELEMENT_TYPES and Paper::ELEMENTS
        common = common_elements
        {
          "front" => object.front_elements.keys.map(&:to_s) & common,
          "back" => object.back_elements.keys.map(&:to_s) & common
        }
      end
    end

    def all_ai_element_types
      if object.is_a?(Input::Theme)
        # For themes, include all AI element types (including portrait)
        Input::Theme::AI_ELEMENT_TYPES
      else
        # For papers, only include common elements
        common_elements
      end
    end

    def all_ai_element_properties
      # Use all AI properties, not just intersection with Paper
      # This ensures resolution and other theme-specific properties are included
      Input::Theme::AI_ELEMENT_PROPERTIES
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

      # First try to get from source, then from defaults, then provide a sensible fallback
      value = source_hash&.dig(element_type, property.to_s) ||
              default_hash.dig(element_type, property.to_s)

      # If still nil, provide sensible defaults based on property
      if value.nil?
        case property.to_s
        when 'x', 'y' then 30
        when 'width', 'height' then 20
        when 'color' then '0, 0, 0'
        when 'opacity' then 1.0
        when 'resolution' then '1024x1024'
        else ''
        end
      else
        value
      end
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
