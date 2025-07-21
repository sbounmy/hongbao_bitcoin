class CheckoutButtonComponent < ApplicationComponent
  def initialize(provider:, price_id:, color: nil, classes: nil, payment_method: nil)
    @provider = provider.to_s
    @price_id = price_id
    @color = color
    @classes = classes
    @payment_method = payment_method
  end

  def button_text
    case provider
    when "btcpay"
      I18n.t(payment_method,
             scope: "components.checkout_button.btcpay",
             default: :default)
    else
      I18n.t("components.checkout_button.#{provider}")
    end
  end

  def button_classes
    base_classes = "w-full cursor-pointer text-center p-4 border rounded-lg text-white transition-colors duration-150 ease-in-out"

    [ base_classes, provider_classes, @classes ].compact.join(" ")
  end

  def form_data
    { turbo: false }
  end

  private

  attr_reader :provider, :price_id, :color, :payment_method

  def provider_classes
    case provider
    when "stripe"
      "bg-blue-500 hover:bg-blue-600"
    when "btcpay"
      case payment_method
      when "BTC-LightningNetwork"
        "bg-purple-500 hover:bg-purple-600"
      else
        "bg-orange-500 hover:bg-orange-600"
      end
    else
      "bg-gray-500 hover:bg-gray-600"
    end
  end
end
