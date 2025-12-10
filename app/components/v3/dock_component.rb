module V3
  class DockComponent < ApplicationComponent
    renders_many :items, "ItemComponent"

    class ItemComponent < ApplicationComponent
      def initialize(label:, icon:, href:, primary: false)
        @label = label
        @icon = icon
        @href = href
        @primary = primary
        @active = false
      end

      def before_render
        @active = request.path == @href
      end

      def active?
        @active
      end

      def primary?
        @primary
      end

      attr_reader :label, :icon, :href
    end
  end
end
