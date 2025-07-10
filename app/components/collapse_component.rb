# frozen_string_literal: true

class CollapseComponent < ApplicationComponent
  # Defines a slot for the component's header/title.
  renders_one :summary

  # @param open [Boolean] Whether the collapsible is open by default.
  # @param id [String] A unique identifier for the collapsible.
  def initialize(id:, open: false)
    @id = id
    @open = open
  end

  private

  attr_reader :open, :id
end
