# frozen_string_literal: true

class V3::ColorSelectorComponent < ApplicationComponent
  renders_many :buttons, "V3::ColorButtonComponent"

  attr_reader :pack, :current_color, :initial_slide_index

  def initialize(pack:, current_color:)
    super()
    @pack = pack
    @current_color = current_color
    current_color_list = current_color.split(",").map(&:to_sym).sort
    @initial_slide_index = 1

    all_colors = available_colors + available_color_combinations

    all_colors.each_with_index do |color_data, index|
      is_selected = if color_data.is_a?(Array)
                      color_data.sort == current_color_list
      else
                      [ color_data ] == current_color_list
      end

      # If this is the selected color, store its index
      @initial_slide_index = index if is_selected && index != 0

      with_button(
        color: color_data,
        label: "Select #{color_data.is_a?(Array) ? "a mix of #{color_data.join(' and ')}" : "#{color_data} color"}",
        selected: is_selected
      )
    end
  end

  private

  def available_colors
    path = Rails.root.join("app/assets/images/plans/#{pack}/*")
    Dir.glob(path)
       .select { |f| File.directory? f }
       .sort
       .map { |d| d.split("/").last.split("_").last.to_sym }
       .uniq
  end

  def available_color_combinations
    if available_colors.size > 1 && [ "family", "maximalist" ].include?(pack)
      available_colors.combination(2).to_a
    else
      []
    end
  end
end
