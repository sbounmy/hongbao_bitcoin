module QrCodeHelper
  def bitcoin_qr_code(data, size: 150, icon: nil)
    qr = RQRCode::QRCode.new(data)
    png = qr.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      fill: "white",
      module_px_size: size / 8,
      resize_exactly_to: size,
      resize_gte_to: false
    )

    if icon.present?
      # Convert PNG to ChunkyPNG::Image for manipulation
      qr_image = ChunkyPNG::Image.from_blob(png.to_s)

      # Load and resize the lock image
      logo_path = Rails.root.join("app", "assets", "images", "#{icon}.png")
      logo = ChunkyPNG::Image.from_file(logo_path)

      # Calculate logo size (25% of QR code size)
      logo_size = (size * 0.25).to_i
      logo = logo.resize(logo_size, logo_size)

      # Create a new image for the white circular background
      circle_size = logo_size + 10  # Add 4px padding on each side
      circle = ChunkyPNG::Image.new(circle_size, circle_size, ChunkyPNG::Color::TRANSPARENT)

      # Draw white circle
      (0...circle_size).each do |x|
        (0...circle_size).each do |y|
          center_x = circle_size / 2.0
          center_y = circle_size / 2.0
          distance = Math.sqrt((x - center_x)**2 + (y - center_y)**2)
          if distance <= circle_size / 2.0
            circle[x, y] = ChunkyPNG::Color::WHITE
          end
        end
      end

      # Calculate position to center the circle and logo
      x_center = (qr_image.width - circle_size) / 2
      y_center = (qr_image.height - circle_size) / 2

      # Composite the white circle onto the QR code
      qr_image.compose!(circle, x_center, y_center)

      # Calculate position to center the logo within the circle
      logo_x = x_center + (circle_size - logo_size) / 2
      logo_y = y_center + (circle_size - logo_size) / 2

      # Composite the logo onto the QR code
      qr_image.compose!(logo, logo_x, logo_y)

      # Convert back to base64
      "data:image/png;base64,#{Base64.strict_encode64(qr_image.to_blob)}"
    else
      # Return simple QR code without icon
      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
    end
  end

  def hongbao_qr_code(address, size: 150)
      # Generate QR code for hongbaob.tc/:address
      url = hong_bao_url(address)
      qr = RQRCode::QRCode.new(url)

      # Generate QR code with logo
      png = qr.as_png(
        bit_depth: 1,
        border_modules: 4,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: "black",
        fill: "white",
        module_px_size: size / 8,
        resize_exactly_to: size,
        resize_gte_to: false
      )

      # Convert to base64
      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
  end

  private

  def format_amount(amount)
    return nil unless amount
    # Convert to decimal and remove trailing zeros
    amount.to_d.to_s("F")
  end
end
