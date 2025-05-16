class AlertComponent < ViewComponent::Base
  attr_accessor :icon, :message

  def initialize(icon: nil, message: nil, **options)
    @icon = icon
    @message = message
    @class = options[:class]
  end
end
