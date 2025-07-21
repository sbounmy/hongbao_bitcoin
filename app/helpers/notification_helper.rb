module NotificationHelper
  def render_notifications(position: "top-center")
    return unless flash.any?

    safe_join(flash.map do |type, message|
      render NotificationComponent.new(
        type: type.to_sym,
        message: message,
        position: position
      )
    end)
  end

  def notification_container
    content_tag :div, "", id: "notification-container"
  end
end
