class FlashComponent < ApplicationComponent
  def initialize(flash:, display_mode: :toast)
    @flash = flash
    @display_mode = display_mode
  end

  def render?
    @flash.any?
  end

  private

  attr_reader :flash, :display_mode

  def flash_classes(type)
    base_classes = "alert"

    type_classes = case type.to_s
    when "notice", "success"
      "alert-success"
    when "alert", "error"
      "alert-error"
    when "warning"
      "alert-warning"
    else
      "alert-info"
    end

    [ base_classes, type_classes ].join(" ")
  end

  def icon_for_type(type)
    case type.to_s
    when "notice", "success"
      "check-circle"
    when "alert", "error"
      "x-circle"
    when "warning"
      "exclamation-triangle"
    else
      "information-circle"
    end
  end

  def auto_dismiss_delay(type)
    case type.to_s
    when "alert", "error"
      8000 # 8 seconds for errors
    else
      5000 # 5 seconds for other messages
    end
  end
end
