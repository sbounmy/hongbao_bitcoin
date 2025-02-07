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
      generation = AiGeneration.find_by(generation_id: generation_id)
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
        Rails.logger.info "Generation updated with images: #{generation.image_urls}"

        Turbo::StreamsChannel.broadcast_update_to(
          "ai_generations",
          target: "ai_generations",
          partial: "hong_baos/new/steps/design/generated_images",
          locals: { image_urls: generation.image_urls }
        )

      end

      render json: { status: "success" }, status: :ok
    end

    private

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
