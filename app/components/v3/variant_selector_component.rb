# frozen_string_literal: true

class V3::VariantSelectorComponent < ApplicationComponent
  renders_many :options, "V3::VariantOptionComponent"

  attr_reader :product, :current_variant_id

  def initialize(product:, current_variant_id: nil)
    super()
    @product = product
    @current_variant_id = current_variant_id

    return unless product

    # Create an option for each non-master variant
    product.available_variants.each do |variant|
      is_selected = variant.id == current_variant_id

      with_option(
        variant: variant,
        selected: is_selected
      )
    end
  end

  class V3::VariantOptionComponent < ViewComponent::Base
    attr_reader :variant, :selected

    def initialize(variant:, selected: false)
      @variant = variant
      @selected = selected
      super()
    end

    def radio_id
      "variant_radio_#{variant.id}"
    end

    def variant_value
      variant.id
    end

    def classes
      base = "block w-16 h-16 rounded-full border-2 shadow-md cursor-pointer flex-shrink-0"
      hover = "hover:scale-110 transition-transform"
      focus = "peer-focus:ring-2 peer-focus:ring-offset-2 peer-focus:ring-blue-500"
      selected_state = selected ? "border-blue-300 ring-2 ring-blue-300" : "border-white"

      "#{base} #{hover} #{focus} #{selected_state}"
    end

    def background_style
      variant.background_style
    end

    def label_text
      variant.color_option_value&.presentation || variant.options_text.presence || "Default"
    end
  end
end
