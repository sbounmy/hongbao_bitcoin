module TurboNotificationHelper
  def turbo_stream_notification(type:, message:, position: "top-center", delay: nil)
    turbo_stream.append "notification-container" do
      render NotificationComponent.new(
        type: type,
        message: message,
        position: position,
        delay: delay
      )
    end
  end

  def turbo_stream_success(message, **options)
    turbo_stream_notification(type: :success, message: message, **options)
  end

  def turbo_stream_error(message, **options)
    turbo_stream_notification(type: :error, message: message, **options)
  end

  def turbo_stream_warning(message, **options)
    turbo_stream_notification(type: :warning, message: message, **options)
  end

  def turbo_stream_info(message, **options)
    turbo_stream_notification(type: :info, message: message, **options)
  end
end
