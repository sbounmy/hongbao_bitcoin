# frozen_string_literal: true

class FlashMessagesComponent < ApplicationComponent
  def initialize(flash:)
    @flash = flash
    super()
  end

  def render?
    flash.any?
  end

  private

  attr_reader :flash
end