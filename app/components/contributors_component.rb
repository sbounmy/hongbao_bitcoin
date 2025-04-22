# frozen_string_literal: true

require "ostruct"
# Renders the Contributors section grid
class ContributorsComponent < ApplicationComponent
  CONTRIBUTORS = [
    OpenStruct.new(name: "Linda", avatar_url: "contributors/linda.jpg", link_url: "https://www.upwork.com/freelancers/eliyam2"),
    OpenStruct.new(name: "Oussama", avatar_url: "contributors/oussama.jpg", link_url: "https://www.linkedin.com/in/daouahi-oussama-39bb192a6")
  ].freeze

  attr_reader :contributors

  # Initializes the component.
  # @param contributors [Array<#name, #avatar_url, optional #link_url>] An array of contributor objects or hashes.
  #                                                                     Defaults to dummy data if empty or nil.
  def initialize(contributors: nil)
    super
    @contributors = (contributors.presence || CONTRIBUTORS)
  end

  def render?
    contributors.any?
  end
end
