class NotificationComponent < ViewComponent::Base
  attr_reader :type, :message, :position, :delay

  def initialize(type:, message:, position: "top-right", delay: nil)
    @type = type
    @message = message
    @position = position
    @delay = delay || default_delay
  end

  private

  def default_delay
    case type
    when :error, :alert
      8000
    else
      5000
    end
  end

  def toast_position_class
    case position
    when "top-left"
      "toast-top toast-start"
    when "top-center"
      "toast-top toast-center"
    when "top-right"
      "toast-top toast-end"
    when "bottom-left"
      "toast-bottom toast-start"
    when "bottom-center"
      "toast-bottom toast-center"
    when "bottom-right"
      "toast-bottom toast-end"
    else
      "toast-top toast-end"
    end
  end

  def alert_type_class
    case type
    when :success
      "alert-success"
    when :error, :alert
      "alert-error"
    when :warning
      "alert-warning"
    else
      "alert-info"
    end
  end

  def icon_name
    case type
    when :success
      "check-circle"
    when :error, :alert
      "x-circle"
    when :warning
      "exclamation-triangle"
    else
      "information-circle"
    end
  end
end
