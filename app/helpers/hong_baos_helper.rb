module HongBaosHelper
  def number_to_btc(amount)
    number_with_precision(amount, precision: 8, delimiter: ",")
  end

  # Creates a permission request banner for camera/microphone access
  # @param types [Array<String>] List of permissions to request ('video' and/or 'audio')
  # @return [String] HTML for the permission banner
  # @example
  #   <%= permission_banner('video', 'audio') %> # Requests both camera and mic
  #   <%= permission_banner('video') %>          # Requests only camera
  #
  # @note Permission Errors:
  #   The getUserMedia API requires:
  #   - A secure context (HTTPS or localhost)
  #   - Firefox: about:preferences#privacy to manage permissions
  #   - Chrome: chrome://settings/content/camera
  #   - Safari: System Preferences > Security & Privacy
  #
  #   Common errors:
  #   - DOMException: "The request is not allowed by the user agent or the platform"
  #     Usually means permissions were denied or the context isn't secure
  def permission_banner(*types)
    tag.div(
      data: {
        controller: "permission",
        "permission-types-value": types.to_json,
        "permission-hidden-class": "hidden"
      }
    ) do
      tag.div(
        class: "bg-orange-500 text-white p-4 cursor-pointer",
        data: {
          action: "click->permission#ask"
        }
      ) do
        "Please enable camera and microphone access to use this feature"
      end
    end
  end

  # Creates an error message target for the form_controller
  # @return [String] HTML for the error message target
  def error_message_target(controller: "form")
    tag.div(
      data: { "#{controller}_target": "errorMessage" },
      class: "flex items-center gap-2 text-white text-sm mt-2 hidden"
    ) do
      concat(heroicon "exclamation-triangle", variant: :solid, class: "h-5 w-5 text-yellow-500")
      concat(tag.span)
    end
  end
end
