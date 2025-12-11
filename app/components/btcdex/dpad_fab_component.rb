# frozen_string_literal: true

module Btcdex
  class DpadFabComponent < ApplicationComponent
    renders_many :actions, "ActionItem"

    class ActionItem < ApplicationComponent
      def initialize(label:, icon:, href:)
        @label = label
        @icon = icon
        @href = href
      end

      attr_reader :label, :icon, :href
    end
  end
end
