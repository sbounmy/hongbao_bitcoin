module FlashHelper
  def flash_component(display_mode = :toast)
    render FlashComponent.new(flash: flash, display_mode: display_mode) if flash.any?
  end

  def flash_alert(message, type = :info)
    flash[type] = message
  end

  def flash_success(message)
    flash_alert(message, :success)
  end

  def flash_error(message)
    flash_alert(message, :error)
  end

  def flash_warning(message)
    flash_alert(message, :warning)
  end

  def flash_info(message)
    flash_alert(message, :info)
  end
end
