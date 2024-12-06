require "rqrcode"
require "image_processing/vips"

namespace :qr do
  desc "Generate YouTube QR code with logo"
  task generate_youtube: :environment do
    # QR Code configuration
    youtube_url = "https://www.youtube.com/watch?v=qkNhjVJZ4N0"
    qr = RQRCode::QRCode.new(youtube_url, size: 10, level: :h)

    # Generate QR code PNG
    qr_png = qr.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 20
    )

    # Create temporary file for QR code
    qr_temp = Tempfile.new([ "youtube_qr", ".png" ])
    qr_png.save(qr_temp.path)

    # Load and process logo
    youtube_logo_path = Rails.root.join("app/assets/images/pdf/youtube-logo.png")
    logo = ImageProcessing::Vips
      .source(youtube_logo_path)
      .resize_to_fit(300, 300)
      .call(save: false)

    # Calculate center position
    qr_image = Vips::Image.new_from_file(qr_temp.path)
    center_x = (qr_image.width - logo.width) / 2
    center_y = (qr_image.height - logo.height) / 2

    # Create final composite
    result = ImageProcessing::Vips
      .source(qr_temp.path)
      .composite(logo, gravity: "centre")
      .call

    # Save final QR code
    output_path = Rails.root.join("app/assets/images/pdf/satoshi-mystery.png")
    FileUtils.mkdir_p(File.dirname(output_path))
    FileUtils.cp(result.path, output_path)

    # Clean up
    qr_temp.close!
    puts "QR code generated at: #{output_path}"
  end
end
