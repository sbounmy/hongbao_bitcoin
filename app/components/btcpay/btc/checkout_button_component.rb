module Btcpay
  module Btc
    class CheckoutButtonComponent < ::CheckoutButtonComponent
      def initialize(price_id:, color: nil, classes: nil)
        @price_id = price_id
        @color = color
        @classes = classes
        @payment_method = "BTC"
      end

      private

      attr_reader :payment_method

      def button_text
        I18n.t("BTC",
               scope: "components.checkout_button.btcpay",
               default: :default)
      end

      def button_icon
        image_tag("bitcoin-64x64.svg", class: "h-5 w-5")
      end

      def form_action
        new_checkout_path
      end

      def form_method
        :get
      end

      def provider
        "btcpay"
      end

      def provider_classes
        "bg-orange-500 hover:bg-orange-600"
      end

      def hidden_fields
        super.merge(payment_method: payment_method)
      end
    end
  end
end
