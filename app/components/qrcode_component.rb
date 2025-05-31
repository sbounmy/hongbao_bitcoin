class QrcodeComponent < ApplicationComponent
  attr_reader :url, :size, :options

  def initialize(url:, size:, **options)
    @url = url
    @size = size
    @options = options
  end

  def qr_code
    qr = RQRCode::QRCode.new(url)

    # Generate QR code
    png = qr.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      fill: "white",
      resize_exactly_to: size,
      # module_px_size is ignored if resize_exactly_to is present,
      # or we could calculate it as (size / qr.module_count.to_f).ceil
      # but resize_exactly_to is generally sufficient.
      resize_gte_to: false
    )

    # Convert to base64
    "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
  end
end
