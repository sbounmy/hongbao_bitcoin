module Orders
  class StatusComponent < ApplicationComponent
    def initialize(order:)
      @order = order
    end

    def status_color
      case order.state
      when "pending"
        "text-yellow-600"
      when "processing"
        "text-blue-600"
      when "completed"
        "text-green-600"
      when "failed"
        "text-red-600"
      else
        "text-gray-600"
      end
    end

    def status_bg_color
      case order.state
      when "pending"
        "bg-yellow-50"
      when "processing"
        "bg-blue-50"
      when "completed"
        "bg-green-50"
      when "failed"
        "bg-red-50"
      else
        "bg-gray-50"
      end
    end

    def status_icon
      case order.state
      when "pending"
        "clock"
      when "processing"
        "arrow-path"
      when "completed"
        "check-circle"
      when "failed"
        "x-circle"
      else
        "question-mark-circle"
      end
    end

    def status_message
      case order.state
      when "pending"
        "Waiting for payment confirmation"
      when "processing"
        "Payment detected, confirming transaction"
      when "completed"
        "Payment confirmed! Your order is complete"
      when "failed"
        "Payment failed or expired"
      else
        "Unknown status"
      end
    end

    def should_poll?
      %w[pending processing].include?(order.state)
    end

    def poll_interval
      case order.state
      when "processing"
        3000 # 3 seconds for processing (faster updates)
      else
        5000 # 5 seconds for pending
      end
    end

    private

    attr_reader :order
  end
end
