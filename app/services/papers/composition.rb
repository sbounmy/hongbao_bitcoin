require "vips"

module Papers
  class Composition < ApplicationService
    def call(template:, portrait:, config:)
      @template = template
      @portrait = portrait
      @config = config

      composite_portrait
    end

    private

    def composite_portrait
      # Load template image
      template_path = ActiveStorage::Blob.service.path_for(@template.key)
      template_image = Vips::Image.new_from_file(template_path)

      Rails.logger.info "[Papers::Composition] Template dimensions: #{template_image.width}x#{template_image.height}"

      # Calculate pixel positions from percentages
      portrait_x = (template_image.width * @config["x"].to_i / 100.0).round
      portrait_y = (template_image.height * @config["y"].to_i / 100.0).round
      portrait_width = (template_image.width * @config["width"].to_i / 100.0).round
      portrait_height = (template_image.height * @config["height"].to_i / 100.0).round

      Rails.logger.info "[Papers::Composition] Portrait position: (#{portrait_x}, #{portrait_y}) size: #{portrait_width}x#{portrait_height}"

      # Load and prepare portrait
      portrait_image = if @portrait.is_a?(String)
        # If portrait is a binary string/blob
        Vips::Image.new_from_buffer(@portrait, "")
      else
        # If portrait is an ActiveStorage attachment
        portrait_path = ActiveStorage::Blob.service.path_for(@portrait.key)
        Vips::Image.new_from_file(portrait_path)
      end

      # Smart crop portrait to target dimensions
      prepared_portrait = portrait_image.thumbnail_image(portrait_width,
        height: portrait_height,
        crop: :attention  # Focuses on faces and interesting areas
      )

      # Composite portrait onto template
      result = template_image.composite(prepared_portrait, :over,
        x: portrait_x,
        y: portrait_y
      )

      # Convert to JPEG buffer with high quality
      result.write_to_buffer(".jpg", Q: 90)
    end
  end
end
