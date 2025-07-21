module Checkout
  module Btcpay
    class Success < Checkout::Success
      def call(identifier)
        # Find the order by redirect_ref
        order = Order.find_by(redirect_ref: identifier)

        # we check for the existence of the order
        return failure("Order not found") unless order

        # The webhook handles all state transitions, so we just return the order
        success(order)
      end
    end
  end
end
