module QrCodeHelper
  def qr_code(url, size: 150)
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
