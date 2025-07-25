module Stripe
  class CheckoutButtonComponent < ::CheckoutButtonComponent
    def initialize(price_id:, color: nil, classes: nil)
      @price_id = price_id
      @color = color
      @classes = classes
    end

    private

    def button_text
      I18n.t("components.checkout_button.stripe")
    end

    def button_icon
      heroicon "credit-card", variant: :solid, class: "h-5 w-5"
    end

    def form_action
      checkout_index_path
    end

    def form_method
      :post
    end

    def provider
      "stripe"
    end

    def provider_classes
      "bg-blue-500 hover:bg-blue-600"
    end
  end
end
