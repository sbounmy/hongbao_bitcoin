module QrCodeHelper
  def qr_code(url, size: 150, image: nil)
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


    if image.present?
        # Load and process center image
        center_img = ChunkyPNG::Image.from_file(image)
        image_size = (size * 0.25).to_i # 25% of QR code size
        center_img = center_img.resize(image_size, image_size)

        # Calculate center position
        x = (size - image_size) / 2
        y = (size - image_size) / 2

        # Composite images
        png.compose!(center_img, x, y)
        Rails.logger.error "Failed to add center image to QR code: #{e.message}"
    end

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
