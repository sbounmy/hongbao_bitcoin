module Admin
  module Orders
    class StatusBadgeComponent < ApplicationComponent
      def initialize(status:, size: :md)
        @status = status.to_s
        @size = size
      end

      def badge_classes
        base_classes = "badge"
        size_classes = size_class
        status_classes = status_class

        [ base_classes, size_classes, status_classes ].compact.join(" ")
      end

      private

      attr_reader :status, :size

      def size_class
        case size
        when :sm
          "badge-sm"
        when :lg
          "badge-lg"
        else
          "badge-md"
        end
      end

      def status_class
        case status
        when "pending"
          "badge-warning"
        when "processing"
          "badge-info"
        when "completed"
          "badge-success"
        when "failed"
          "badge-error"
        else
          "badge-neutral"
        end
      end
    end
  end
end
