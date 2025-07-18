module Orders
  class ItemComponent < ApplicationComponent
    def initialize(order:)
      @order = order
    end

    def status_badge_classes
      case order.state
      when "pending"
        "badge badge-warning"
      when "processing"
        "badge badge-info"
      when "completed"
        "badge badge-success"
      when "failed"
        "badge badge-error"
      else
        "badge badge-neutral"
      end
    end

    def provider_badge_classes
      case order.payment_provider
      when "stripe"
        "badge badge-primary"
      when "btcpay"
        "badge badge-accent"
      else
        "badge badge-neutral"
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

    private

    attr_reader :order
  end
end
