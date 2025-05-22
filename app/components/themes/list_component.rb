# frozen_string_literal: true

module Themes
  class ListComponent < ViewComponent::Base
    with_collection_parameter :theme

    def initialize(theme:)
      @theme = theme
    end

    private

    attr_reader :theme
  end
end
