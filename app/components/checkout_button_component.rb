class CheckoutButtonComponent < ApplicationComponent
  def initialize(provider:, price_id:, color: nil, classes: nil)
    @provider = provider.to_s
    @price_id = price_id
    @color = color
    @classes = classes
  end

  def button_text
    I18n.t("components.checkout_button.#{provider}")
  end

  def button_classes
    base_classes = "w-full cursor-pointer text-center p-4 border rounded-lg text-white transition-colors duration-150 ease-in-out"

    [ base_classes, provider_classes, @classes ].compact.join(" ")
  end

  def form_data
    { turbo: false }
  end

  private

  attr_reader :provider, :price_id, :color

  def provider_classes
    case provider
    when "stripe"
      "bg-blue-500 hover:bg-blue-600"
    when "btcpay"
      "bg-orange-500 hover:bg-orange-600"
    else
      "bg-gray-500 hover:bg-gray-600"
    end
  end
end
