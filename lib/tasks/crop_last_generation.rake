require "open-uri"

namespace :test do
  desc "Crop the last AI generation image into front and back"
  task crop_last_generation: :environment do
    # Set default host for URL generation
    Rails.application.routes.default_url_options[:host] = "localhost:3000"

    generation = AiGeneration.last

    if generation.nil? || generation.image_urls.empty?
      puts "No AI generation found with images"
      exit
    end

    image_url = generation.image_urls.first
    puts "Processing image: #{image_url}"

    begin
      # Create a new paper record
      paper = Paper.new(
        name: "Test Split - #{Time.current.to_i}",
        style: :modern,
        active: true
      )

      # Download and verify the source image
      source_image = URI.open(image_url)
      puts "Source image downloaded successfully"

      # Process and verify the initial resize
      processed_image = ImageProcessing::Vips
        .source(source_image)
        .resize_to_fill(512, 512)
        .convert("png")
        .call

      vips_image = Vips::Image.new_from_file(processed_image.path)
      puts "Initial image processing successful"
      puts "Processed image dimensions: #{vips_image.width}x#{vips_image.height}"

      # Process top half with verification
      puts "Processing top half..."
      top_half = ImageProcessing::Vips
        .source(processed_image)
        .crop(0, 0, 512, 256)
        .convert("png")
        .call

      puts "Top half processed successfully"

      # Process bottom half with verification
      puts "Processing bottom half..."
      bottom_half = ImageProcessing::Vips
        .source(processed_image)
        .crop(0, 256, 512, 256)
        .convert("png")
        .call

      puts "Bottom half processed successfully"

      # Save temporary files for verification
      temp_dir = Rails.root.join("tmp", "image_processing")
      FileUtils.mkdir_p(temp_dir)

      top_temp_path = temp_dir.join("top_half.png")
      bottom_temp_path = temp_dir.join("bottom_half.png")

      # Copy the processed files to temp location
      FileUtils.cp(top_half.path, top_temp_path)
      FileUtils.cp(bottom_half.path, bottom_temp_path)

      # Attach the images to the paper record
      paper.image_front.attach(
        io: File.open(top_temp_path),
        filename: "front_#{SecureRandom.hex(8)}.png",
        content_type: "image/png"
      )

      paper.image_back.attach(
        io: File.open(bottom_temp_path),
        filename: "back_#{SecureRandom.hex(8)}.png",
        content_type: "image/png"
      )

      if paper.save
        puts "Successfully created paper ##{paper.id}"
        puts "Front image URL: #{Rails.application.routes.url_helpers.url_for(paper.image_front)}"
        puts "Back image URL: #{Rails.application.routes.url_helpers.url_for(paper.image_back)}"

      else
        puts "Failed to save paper:"
        puts paper.errors.full_messages
      end

    rescue StandardError => e
      puts "Error processing image: #{e.message}"
      puts e.backtrace
    ensure
      # Clean up temporary files
      FileUtils.rm_f(top_temp_path) if defined?(top_temp_path) && File.exist?(top_temp_path)
      FileUtils.rm_f(bottom_temp_path) if defined?(bottom_temp_path) && File.exist?(bottom_temp_path)
    end
  end
end
