# frozen_string_literal: true

class BottomSheetComponent < ApplicationComponent
  renders_one :trigger
  renders_one :header

  def initialize(id:)
    @id = id
  end

  private

  attr_reader :id
end
