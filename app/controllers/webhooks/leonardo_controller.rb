require "open-uri"
require "net/http"

module Webhooks
  class LeonardoController < ApplicationController
    skip_before_action :require_authentication, only: [ :webhook ]
    skip_before_action :verify_authenticity_token, only: [ :webhook ]
    before_action :verify_webhook_token, only: [ :webhook ]

    def webhook
      payload = JSON.parse(request.body.read)
      Rails.logger.info "Webhook received with payload: #{payload}"

      # Extract generation ID from the payload
      generation_id = payload.dig("data", "object", "id")
      Rails.logger.info "Generation ID: #{generation_id}"

      # Find the associated generation request
      generation = Ai::Generation.find_by(generation_id: generation_id)
      Rails.logger.info "Found generation: #{generation&.id}"

      return head :not_found unless generation

      if payload["type"] == "image_generation.complete"
        # Get the generated images from the payload
        images = payload.dig("data", "object", "images") || []

        # Update the generation with results
        generation.update!(
          status: "completed",
          image_urls: images.map { |img| img["url"] }
        )
        images.each do |image|
          downloaded_image = URI.parse(image["url"]).open
          generation.generated_images.attach(io: downloaded_image, filename: "#{SecureRandom.hex(8)}.jpg")
        end
        Rails.logger.info "Generation updated with images: #{generation.image_urls}"

        if generation.face_to_swap.attached?
          process_face_swap(generation)
        end

        if generation.image_urls.present?
          process_images(generation)
        end
      end

      render json: { status: "success" }, status: :ok
    end

    private

    def process_images(generation)
      image_urls = generation.image_urls
      image_urls.each do |image_url|
      temp_file = Tempfile.new([ "downloaded_image", ".png" ])
      paper = Paper.new(
        name: "AI Generated #{generation.prompt}",
        style: :modern,
        active: true,
        public: false,
        user: generation.user
      )

      top_temp_path, bottom_temp_path = process_image(image_url, temp_file)
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

      paper.save!

      # Clean up temporary files
      FileUtils.rm_f(top_temp_path)
      FileUtils.rm_f(bottom_temp_path)
      temp_file.close
      temp_file.unlink
      end
      # Update generation with paper reference
      Turbo::StreamsChannel.broadcast_update_to(
        "ai_generations",
        target: "ai_generations",
        partial: "hong_baos/new/steps/design/generated_designs",
        locals: { papers_by_user: current_user.papers }
      )
    rescue StandardError => e
      Rails.logger.error "Image processing error: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    def process_face_swap(generation)
      face_to_swap = generation.face_to_swap
      image_url = generation.generated_images.first
      swap_result = FaceSwapService.swap_faces(face_to_swap, image_url, "https://reliably-decent-oarfish.ngrok-free.app/webhooks/face_swap")
      Rails.logger.info "Face swap result: #{swap_result}"
      # if swap_result && swap_result["status"] == "success"
      #   generation.update!(image_urls: [ swap_result["result_url"] ])
      # end
    end

    def verify_webhook_token
      provided_token = request.headers["Authorization"]
      expected_token = "Bearer #{Rails.application.credentials.dig(:leonardo, :webhook_token)}"

      Rails.logger.info "Webhook auth - Provided token: #{provided_token}"
      Rails.logger.info "Webhook auth - Expected token: #{expected_token}"

      unless provided_token && ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)
        Rails.logger.error "Webhook authentication failed"
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end

    def process_image(image_url, temp_file)
      # Download and verify the source image using Net::HTTP
      uri = URI.parse(image_url)
      response = Net::HTTP.get_response(uri)

      # Create a temporary file to store the downloaded image

      temp_file.binmode
      temp_file.write(response.body)
      temp_file.rewind

      Rails.logger.info "Source image downloaded successfully"

      # Process and verify the initial resize
      processed_image = ImageProcessing::Vips
        .source(temp_file)
        .resize_to_fill(512, 512)
        .convert("png")
        .call

      # Process top half
      Rails.logger.info "Processing top half..."
      top_half = ImageProcessing::Vips
        .source(processed_image)
        .crop(0, 0, 512, 256)
        .convert("png")
        .call

      # Process bottom half
      Rails.logger.info "Processing bottom half..."
      bottom_half = ImageProcessing::Vips
        .source(processed_image)
        .crop(0, 256, 512, 256)
        .convert("png")
        .call

      # Save temporary files for verification
      temp_dir = Rails.root.join("tmp", "image_processing")
      FileUtils.mkdir_p(temp_dir)

      top_temp_path = temp_dir.join("top_half.png")
      bottom_temp_path = temp_dir.join("bottom_half.png")

      # Copy the processed files to temp location
      FileUtils.cp(top_half.path, top_temp_path)
      FileUtils.cp(bottom_half.path, bottom_temp_path)

      return top_temp_path, bottom_temp_path
    end
  end
end
