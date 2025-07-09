# frozen_string_literal: true

module Inputs
  module Themes
    class CardComponent < ApplicationComponent
      with_collection_parameter :theme

      def initialize(theme:)
        @theme = theme
      end

      private

      attr_reader :theme

      def name
        @theme.name
      end

      def image_url
        if @theme.image.attached?
          @theme.image
        else
          "https://placehold.co/600x400"
        end
      end
    end
  end
end