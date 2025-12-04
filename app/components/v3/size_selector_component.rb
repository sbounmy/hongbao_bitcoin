# frozen_string_literal: true

class V3::SizeSelectorComponent < ApplicationComponent
  renders_many :options, "V3::SizeOptionComponent"

  attr_reader :product, :selected_variant_id

  def initialize(product:, selected_variant_id: nil)
    super()
    @product = product
    @selected_variant_id = selected_variant_id

    return unless product

    # Get the size of the selected variant to determine which size option is selected
    selected_variant = product.variants.find_by(id: selected_variant_id)
    selected_size_id = selected_variant&.size_option_value&.id

    # Create an option for each size option value
    size_option_values.each_with_index do |size_value, index|
      variant = first_variant_for_size(size_value)
      next unless variant # Skip if no variant exists for this size

      is_selected = size_value.id == selected_size_id
      is_default = index == 1 # Family pack is most popular (middle option)

      with_option(
        size_value: size_value,
        variant: variant,
        selected: is_selected,
        default: is_default
      )
    end
  end

  private

  def size_option_values
    OptionValue.for_option_type("size").ordered
  end

  def first_variant_for_size(size_value)
    product.variants.find { |v| v.size_option_value&.id == size_value.id }
  end

  class V3::SizeOptionComponent < ViewComponent::Base
    attr_reader :size_value, :variant, :selected, :default

    def initialize(size_value:, variant:, selected: false, default: false)
      @size_value = size_value
      @variant = variant
      @selected = selected
      @default = default
      super()
    end

    def radio_id
      "size_radio_#{size_value.id}"
    end

    def formatted_price
      helpers.number_to_currency(variant.price, unit: "€", format: "%n%u", strip_insignificant_zeros: true)
    end

    def formatted_description
      case size_value.name
      when "mini"
        "1 pack (6 envelopes) + 12 AI credits"
      when "family"
        "2 packs (12 envelopes) + 24 AI credits"
      when "maximalist"
        "4 packs (24 envelopes) + 42 AI credits"
      else
        size_value.presentation
      end
    end

    def envelopes_count
      case size_value.name
      when "mini" then 6
      when "family" then 12
      when "maximalist" then 24
      else 6
      end
    end

    def price_per_envelope
      (variant.price.to_f / envelopes_count).round(2)
    end

    def formatted_price_per_envelope
      helpers.number_to_currency(price_per_envelope, unit: "€", format: "%n%u")
    end

    def display_name
      case size_value.name
      when "mini" then "Mini Pack"
      when "family" then "Family Pack"
      when "maximalist" then "Maximalist Pack"
      else size_value.presentation
      end
    end
  end
end
