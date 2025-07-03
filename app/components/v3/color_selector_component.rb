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
  end

  private

  def available_colors
    # Scan for directories in app/assets/images/plans/{pack}/ to find available colors.
    path = Rails.root.join("app/assets/images/plans/#{pack}/*")
    Dir.glob(path)
       .select { |f| File.directory? f }
       .map { |d| File.basename(d).to_sym }
       .sort
  end
end
