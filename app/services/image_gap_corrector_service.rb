class ImageGapCorrectorService
  def initialize(image_path)
    @image = ChunkyPNG::Image.from_file(image_path)
    @width = @image.width
    @height = @image.height
  end

  def self.correct_gaps(binary_data)
    temp_input = Tempfile.new([ "input", ".png" ])
    temp_output = Tempfile.new([ "output", ".png" ])

    begin
      temp_input.binmode
      temp_input.write(binary_data)
      temp_input.close

      processor = new(temp_input.path)

      if processor.process_to_blob(temp_output.path)
        temp_output.rewind
        temp_output.read
      else
        binary_data
      end

    rescue => e
      Rails.logger.error "ImageGapCorrectorService error: #{e.message}"
      binary_data
    ensure
      temp_input.unlink if temp_input
      temp_output.unlink if temp_output
    end
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

  def is_red?(pixel)
    r = (pixel >> 24) & 0xff
    g = (pixel >> 16) & 0xff
    b = (pixel >> 8) & 0xff

    return false if r < 50 && g < 50 && b < 50

    h, s, v = rgb_to_hsv(r, g, b)

    red_hue = (h >= 0 && h <= 15) || (h >= 345 && h <= 360)
    high_saturation = s > 100
    sufficient_value = v > 80

    red_dominant = r > g + 30 && r > b + 30
    red_strong = r > 120
    not_too_green = g < r * 0.7
    not_too_blue = b < r * 0.7

    hsv_red = red_hue && high_saturation && sufficient_value
    rgb_red = red_dominant && red_strong && not_too_green && not_too_blue

    hsv_red && rgb_red
  end

  def find_red_line
    # Scan from top to 2/3 of image height, but start from row 10 to avoid edge cases
    min_scan_y = 10
    max_scan_y = (@height * 2.0 / 3).to_i

    (min_scan_y...max_scan_y).each do |y|
      red_pixels_positions = []

      # Check ENTIRE width of the image for red pixels
      (0...@width).each do |x|
        pixel = @image[x, y]
        red_pixels_positions << x if is_red?(pixel)
      end

      # Check if red pixels span the ENTIRE width
      if !red_pixels_positions.empty?
        # Find gaps in the red line
        gaps = []
        total_red_pixels = red_pixels_positions.length

        # Check for gaps larger than 5 pixels
        (1...red_pixels_positions.length).each do |i|
          gap_size = red_pixels_positions[i] - red_pixels_positions[i-1] - 1
          gaps << gap_size if gap_size > 5
        end

        # Check coverage from start and end
        starts_near_beginning = red_pixels_positions.first <= 10
        ends_near_end = red_pixels_positions.last >= @width - 10

        # Calculate coverage percentage
        coverage_percentage = (total_red_pixels.to_f / @width) * 100


        # Criteria for FULL-WIDTH red line:
        # 1. Must cover at least 85% of the image width
        # 2. Must start within first 10 pixels
        # 3. Must end within last 10 pixels
        # 4. No more than 3 large gaps (allows for some imperfection)
        if coverage_percentage >= 85 &&
          starts_near_beginning &&
          ends_near_end &&
          gaps.length <= 3

          return y
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
    line_y = find_red_line

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
