module Ai
  module Styles
    class CheckboxComponent < ViewComponent::Base
      def initialize(checkbox:, form:)
        @checkbox = checkbox
        @form = form
      end

      private

      attr_reader :checkbox, :form
    end
  end
end
