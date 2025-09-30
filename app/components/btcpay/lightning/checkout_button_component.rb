module Btcpay
  module Lightning
    class CheckoutButtonComponent < ::CheckoutButtonComponent
      def initialize(variant_id:, classes: nil)
        @variant_id = variant_id
        @classes = classes
        @payment_method = "BTC-LightningNetwork"
      end

      private

      attr_reader :payment_method

      def button_text
        I18n.t("BTC-LightningNetwork",
               scope: "components.checkout_button.btcpay",
               default: :default)
      end

      def button_icon
        heroicon "bolt", variant: :solid, class: "h-5 w-5"
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
        "bg-purple-500 hover:bg-purple-600"
      end

      def hidden_fields
        super.merge(payment_method: payment_method)
      end
    end
  end
end
