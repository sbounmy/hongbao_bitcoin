module HongBaosHelper
  def number_to_btc(amount)
    number_with_precision(amount, precision: 8, delimiter: ",")
  end

  # Creates a permission request banner for camera/microphone access
  # @param types [Array<String>] List of permissions to request (camera, bluetooth, microphone, geolocation)
  # @return [String] HTML for the permission banner
  # @example
  #   <%= permission_banner('camera', 'microphone') %> # Requests both camera and mic
  #   <%= permission_banner('camera') %>          # Requests only camera
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

  def number_to_bitcoin(amount, options = {})
    return "₿0" if amount.nil? || amount.zero?

    # Convert to string with 8 decimal places
    formatted = "%.8f" % amount

    if formatted.start_with?("0.")
      # Find the position of first non-zero digit after decimal
      match_data = formatted.match(/0\.0*[1-9]/)
      significant_index = match_data ? match_data.end(0) : 0

      # Split the string at the first significant digit
      significant = formatted[0...significant_index]
      insignificant = formatted[significant_index..]

      # Remove trailing zeros from insignificant part
      insignificant = insignificant.sub(/0+$/, "") if options[:strip_insignificant_zeros]

      # Build the HTML with different styles for each part
      safe_join([
        content_tag(:span, "₿#{significant}", class: options[:significant_class]),
        content_tag(:span, insignificant, class: options[:insignificant_class])
      ])
    else
      # Handle amounts >= 1 BTC
      whole, decimal = formatted.split(".")
      decimal = decimal.sub(/0+$/, "") if options[:strip_insignificant_zeros]

      safe_join([
        content_tag(:span, "₿#{whole}", class: options[:significant_class]),
        decimal.present? ? content_tag(:span, ".#{decimal}", class: options[:insignificant_class]) : ""
      ])
    end
  end
end
