module Ai
  module Styles
    class CheckboxComponent < ViewComponent::Base
      def initialize(style:, form:)
        @style = style
        @form = form
      end

      private

      attr_reader :style, :form
    end
  end
end
