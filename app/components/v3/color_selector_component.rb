# frozen_string_literal: true

class V3::ColorSelectorComponent < ApplicationComponent
  renders_many :buttons, "V3::ColorButtonComponent"

  attr_reader :pack

  def initialize(pack:)
    super()
    @pack = pack

    available_colors.each do |color|
      with_button(color: color, label: "Select #{color} color")
    end
    if available_colors.size > 1 && [ "family", "maximalist" ].include?(pack)
      available_colors.combination(2).each do |color_pair|
        label = "Select a mix of #{color_pair.first} and #{color_pair.second}"
        with_button(color: :split, label: label, available_colors: color_pair)
      end
    end
  end

  private

  def available_colors
    # Scan for directories in app/assets/images/plans/{pack}/ to find available colors.
    path = Rails.root.join("app/assets/images/plans/#{pack}/*")
    Dir.glob(path)
       .select { |f| File.directory? f }
       .sort
       .map { |d| File.basename(d).split("_").last.to_sym } # Extract just the color name
  end
end
