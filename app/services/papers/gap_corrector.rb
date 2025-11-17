# DEPRECATED: This service is no longer used as of 2025-01-17
# The new composition-based approach uses Papers::Composition instead
# of detecting green lines to crop AI-generated images.
#
# Old flow: AI generates full image → GapCorrector crops by detecting green line
# New flow: AI transforms portrait → Papers::Composition composites onto template
#
# This file is kept for reference only - do not use in new code.

module Papers
  class GapCorrector < ApplicationService
    def call(binary_data)
      @binary_data = binary_data
      @temp_input = nil
      @temp_output = nil

      setup_temp_files
      result = process_image
      cleanup_temp_files

      result
    rescue => e
      cleanup_temp_files
      Rails.logger.error "Gap correction failed: #{e.message}"
      @binary_data
    end

    private

    def setup_temp_files
      @temp_input = Tempfile.new([ "input", ".png" ])
      @temp_output = Tempfile.new([ "output", ".png" ])

      @temp_input.binmode
      @temp_input.write(@binary_data)
      @temp_input.close

      load_image
    end

    def load_image
      @image = ChunkyPNG::Image.from_file(@temp_input.path)
      @width = @image.width
      @height = @image.height
    end

    def process_image
      if process_to_blob(@temp_output.path)
        @temp_output.rewind
        @temp_output.read
      else
        # If processing fails, fall back to splitting image in half and taking upper half
        Rails.logger.info "Gap correction failed, falling back to upper half of image"
        process_upper_half
      end
    end

    def cleanup_temp_files
      @temp_input&.unlink
      @temp_output&.unlink
    end

    def process_upper_half
      # Just crop to 1024x512 from the top
      final_result = crop_image(@image, 1024, 512)
      final_result.save(@temp_output.path)
      @temp_output.rewind
      @temp_output.read
    rescue => e
      Rails.logger.error "Error processing upper half: #{e.message}"
      @binary_data
    end

    def rgb_to_hsv(r, g, b)
      r, g, b = r / 255.0, g / 255.0, b / 255.0

      max_val = [ r, g, b ].max
      min_val = [ r, g, b ].min
      delta = max_val - min_val

      v = max_val
      s = max_val == 0 ? 0 : delta / max_val

      if delta == 0
        h = 0
      elsif max_val == r
        h = 60 * (((g - b) / delta) % 6)
      elsif max_val == g
        h = 60 * (((b - r) / delta) + 2)
      else
        h = 60 * (((r - g) / delta) + 4)
      end

      [ h, s * 255, v * 255 ]
    end

    # Updated to detect GREEN lines instead of red.
    def is_green?(pixel)
      r = (pixel >> 24) & 0xff
      g = (pixel >> 16) & 0xff
      b = (pixel >> 8) & 0xff

      # Green must be dominant
      green_dominant = g > r && g > b

      # Exclude colors with too much blue
      blue_ratio = b.to_f / g
      not_too_blue = blue_ratio < 0.5  # Blue should be less than 50% of green

      not_cyan = g > b * 1.5  # Green must be at least 1.5x blue

      max_blue_standard = 100  # For standard criteria
      max_blue_pure = 50       # For "pure" green criteria

      ultra_pure = g >= 240 && r < 30 && b < 30

      max_saturation = g >= 250 && (r + b) < 120 && b < max_blue_pure

      electric = g >= 230 && g > r + 100 && g > b + 100 && not_too_blue

      perfect = g == 255 && r < 20 && b < 20

      high_intensity = g >= 220 && green_dominant && g > r + 60 && g > b + 60 && b < max_blue_standard && not_cyan

      bright_lime = g >= 200 && r < 180 && b < 80 && g > r + 50

      bright_spring = g >= 200 && b < 100 && r < 80 && g > b + 80 && not_cyan

      bright_green = g >= 180 && green_dominant && g > r + 30 && g > b + 30 && b < max_blue_standard && not_cyan

      light_saturated = g >= 200 && green_dominant && (g - r > 40 || g - b > 40) && b < max_blue_standard && not_too_blue

      # Exclude near-white colors
      total_brightness = r + g + b
      not_too_pale = total_brightness < 720

      (ultra_pure || max_saturation || electric || perfect ||
       high_intensity || bright_lime || bright_spring ||
       (bright_green && not_too_pale && not_too_blue) ||
       (light_saturated && not_too_pale && not_too_blue))
    end

    def find_green_line
      # Scan from top to 2/3 of image height, but start from row 200 to avoid edge cases
      min_scan_y = 200 # change to 200 to speed up processing
      max_scan_y = (@height * 2.0 / 3).to_i

      (min_scan_y...max_scan_y).each do |y|
        # Skip if we can't check the next row
        next if y + 1 >= max_scan_y

        green_pixels_positions = []

        # Check ENTIRE width of the image for green pixels in current row
        (0...@width).each do |x|
          pixel = @image[x, y]
          green_pixels_positions << x if is_green?(pixel)
        end

        # Check if green pixels span the ENTIRE width
        if !green_pixels_positions.empty?
          # Find ALL gaps in the green line
          gaps = []
          total_green_pixels = green_pixels_positions.length

          # Check for ANY significant gaps
          (1...green_pixels_positions.length).each do |i|
            gap_size = green_pixels_positions[i] - green_pixels_positions[i-1] - 1
            gaps << gap_size if gap_size > 0
          end

          # Find the maximum gap size
          max_gap = gaps.max || 0

          # Check coverage from start and end
          starts_near_beginning = green_pixels_positions.first <= 10
          ends_near_end = green_pixels_positions.last >= @width - 10

          # Calculate coverage percentage
          coverage_percentage = (total_green_pixels.to_f / @width) * 100

          if coverage_percentage >= 90 &&
            starts_near_beginning &&
            ends_near_end &&
            max_gap <= 5 &&  # Allow larger gaps for overlaid elements
            gaps.length <= 10  # AI might have overlaid text/logos

            # Check next row for continuity
            next_row_green_pixels = []
            (0...@width).each do |x|
              pixel = @image[x, y + 1]
              next_row_green_pixels << x if is_green?(pixel)
            end

            if !next_row_green_pixels.empty?
              # Calculate next row coverage
              next_row_coverage = (next_row_green_pixels.length.to_f / @width) * 100
              next_row_starts_near_beginning = next_row_green_pixels.first <= 10
              next_row_ends_near_end = next_row_green_pixels.last >= @width - 10

              # Check if next row also meets the green line criteria
              if next_row_coverage >= 90 &&
                next_row_starts_near_beginning &&
                next_row_ends_near_end
                return y
              end
            end
          end
        end
      end

      nil
    end

    def resize_image_section(start_y, end_y, new_height)
      section_height = end_y - start_y

      if section_height <= 0
        new_image = ChunkyPNG::Image.new(@width, new_height)
        (0...new_height).each do |new_y|
          (0...@width).each do |x|
            new_image[x, new_y] = @image[x, start_y.clamp(0, @height - 1)]
          end
        end
        return new_image
      end

      new_image = ChunkyPNG::Image.new(@width, new_height)

      (0...new_height).each do |new_y|
        orig_y = start_y + (new_y * section_height / new_height.to_f).to_i
        orig_y = [ orig_y, end_y - 1 ].min

        (0...@width).each do |x|
          new_image[x, new_y] = @image[x, orig_y]
        end
      end

      new_image
    end

    def resize_image(image, new_width, new_height)
      old_width = image.width
      old_height = image.height

      new_image = ChunkyPNG::Image.new(new_width, new_height)

      (0...new_height).each do |new_y|
        (0...new_width).each do |new_x|
          orig_x = (new_x * old_width / new_width.to_f).to_i
          orig_y = (new_y * old_height / new_height.to_f).to_i

          orig_x = [ orig_x, old_width - 1 ].min
          orig_y = [ orig_y, old_height - 1 ].min

          new_image[new_x, new_y] = image[orig_x, orig_y]
        end
      end

      new_image
    end

    def crop_image(image, width, height)
      cropped = ChunkyPNG::Image.new(width, height)

      (0...height).each do |y|
        (0...width).each do |x|
          if x < image.width && y < image.height
            cropped[x, y] = image[x, y]
          else
            cropped[x, y] = ChunkyPNG::Color::WHITE
          end
        end
      end

      cropped
    end

    def process_to_blob(output_path)
      line_y = find_green_line

      if line_y.nil?
        return false
      end

      if line_y < 10
        line_y = 10
      end

      top_resized = resize_image_section(0, line_y, 512)

      if top_resized.nil?
        return false
      end

      if top_resized.width != 1024
        aspect_ratio = top_resized.height.to_f / top_resized.width
        new_height = (1024 * aspect_ratio).to_i
        top_resized = resize_image(top_resized, 1024, new_height)
      end

      final_result = crop_image(top_resized, 1024, 512)
      final_result.save(output_path)

      true
    rescue => e
      Rails.logger.error "Error processing image: #{e.message}"
      false
    end
  end
end
