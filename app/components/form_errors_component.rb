# frozen_string_literal: true

class FormErrorsComponent < ApplicationComponent
  def initialize(model:)
    @model = model
    super()
  end

  def render?
    model&.errors&.any?
  end

  private

  attr_reader :model
end
