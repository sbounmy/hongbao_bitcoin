module QrCodeHelper
  def bitcoin_qr_code(data, size: 150)
    Rails.cache.fetch("bitcoin_qr/#{data}/#{size}", expires_in: 1.month) do
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

      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
    end
  end

  private

  def format_amount(amount)
    return nil unless amount
    # Convert to decimal and remove trailing zeros
    amount.to_d.to_s("F")
  end
end
