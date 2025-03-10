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
      generation = Ai::Generation.find_by(external_id: generation_id)
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
          generation.images.attach(io: downloaded_image, filename: "#{SecureRandom.hex(8)}.jpg")
        end
        Rails.logger.info "Generation updated with images: #{generation.image_urls}"

        # Process images and create paper if we have images
        if generation.images.present?
          generation.images.each do |image|
            process_images(generation, image)
          end
        end
      end

      render json: { status: "success" }, status: :ok
    end

    private

    def process_images(generation, image)
      # Create a new Paper record using the user from the generation
      paper = Paper.new(
        name: "AI Generated #{generation.prompt}",
        style: :modern,
        active: true,
        public: false,
        user: generation.user
      )

      # Process and verify the initial resize
      processed_image = nil
      image.blob.open do |tempfile|
        processed_image = ImageProcessing::Vips
          .source(tempfile.path)
          .resize_to_fill(512, 512)
          .convert("png")
          .call
      end

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

      # Attach the images to the paper record
      paper.image_front.attach(
        io: File.open(top_half.path),
        filename: "front_#{SecureRandom.hex(8)}.png",
        content_type: "image/png"
      )

      paper.image_back.attach(
        io: File.open(bottom_half.path),
        filename: "back_#{SecureRandom.hex(8)}.png",
        content_type: "image/png"
      )

      paper.save!

      user = User.find(generation.user_id)
      Turbo::StreamsChannel.broadcast_update_to(
        "ai_generations_#{user.id}",
        target: "ai_generations_#{user.id}",
        partial: "hong_baos/new/steps/design/generated_designs",
        locals: { papers_by_user: user.papers, user: user }
      )
    rescue StandardError => e
      Rails.logger.error "Image processing error: #{e.message}\n#{e.backtrace.join("\n")}"
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
  end
end
