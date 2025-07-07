# frozen_string_literal: true

class CollapseComponent < ApplicationComponent
  # Defines a slot for the component's header/title.
  renders_one :summary

  # @param open [Boolean] Whether the collapsible is open by default.
  def initialize(open: false)
    @open = open
  end

  private

  attr_reader :open
end
