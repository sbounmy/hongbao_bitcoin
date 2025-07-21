# Base class for all checkout button components
class CheckoutButtonComponent < ApplicationComponent
  def initialize(price_id:, color: nil, classes: nil)
    @price_id = price_id
    @color = color
    @classes = classes
  end

  def button_text
    raise NotImplementedError, "Subclasses must implement button_text"
  end

  def button_icon
    # Optional - subclasses can override if they want an icon
    nil
  end

  def button_classes
    base_classes = "w-full cursor-pointer p-4 border rounded-lg text-white transition-colors duration-150 ease-in-out"

    [ base_classes, provider_classes, @classes ].compact.join(" ")
  end

  def form_data
    { turbo: false }
  end

  def form_action
    raise NotImplementedError, "Subclasses must implement form_action"
  end

  def render?
    price_id.present?
  end

  def form_method
    raise NotImplementedError, "Subclasses must implement form_method"
  end

  def provider
    raise NotImplementedError, "Subclasses must implement provider"
  end

  protected

  attr_reader :price_id, :color, :classes

  def provider_classes
    raise NotImplementedError, "Subclasses must implement provider_classes"
  end

  def hidden_fields
    fields = {
      provider: provider,
      price_id: price_id
    }
    fields[:color] = color if color.present?
    fields
  end
end
