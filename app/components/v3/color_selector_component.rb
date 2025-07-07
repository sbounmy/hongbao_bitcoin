# frozen_string_literal: true

class V3::ColorSelectorComponent < ApplicationComponent
  renders_many :buttons, "V3::ColorButtonComponent"

  # FIX: Remove initial_slide_index as it's no longer needed.
  attr_reader :pack, :current_color

  def initialize(pack:, current_color:)
    super()
    @pack = pack
    @current_color = current_color
    current_color_list = current_color.split(",").map(&:to_sym).sort

    all_colors = discover_available_colors

    all_colors.each do |color_data|
      is_selected = if color_data.is_a?(Array)
                      color_data.sort == current_color_list
      else
                      [ color_data ] == current_color_list
      end

      with_button(
        color: color_data,
        label: "Select #{color_data.is_a?(Array) ? "a mix of #{color_data.join(' and ')}" : "#{color_data} color"}",
        selected: is_selected
      )
    end
  end

  private

  def discover_available_colors
    path = Rails.root.join("app/assets/images/plans", pack, "*")

    Dir.glob(path).sort.map do |dir_path|
      next unless File.directory?(dir_path)

      folder_name = File.basename(dir_path) # for example 001_red or 005_split_orange_red

      if folder_name.include?("split_")
        # Extract "orange_red" from "005_split_orange_red"
        color_string = folder_name.split("split_").last
        # Convert "orange_red" to [:orange, :red]
        color_string.split("_").map(&:to_sym)
      else
        # Extract :red from "001_red"
        folder_name.split("_").last.to_sym
      end
    end.compact
  end
end
