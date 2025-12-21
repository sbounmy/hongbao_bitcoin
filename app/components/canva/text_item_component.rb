# frozen_string_literal: true

module Canva
  class TextItemComponent < ItemComponent
    private

    def controller_name
      "text-item"
    end

    def item_type
      item[:type] == "mnemonic" ? "mnemonic" : "text"
    end

    def text_data
      {
        "#{data_prefix}_text_value": item[:text],
        "#{data_prefix}_type_value": item_type,
        "#{data_prefix}_font_size_value": item[:size],
        "#{data_prefix}_font_color_value": item[:color]
      }
    end
  end
end
