module Ai
  class ImagesController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [ :done ]
    allow_unauthenticated_access only: [ :done ]
    before_action :verify_webhook_token, only: [ :done ]

    def create
      result = Ai::Images::Create.call(params: image_params, user: current_user)
      if result.success?
        render json: { success: true, image: result.payload }
      else
        render json: { success: false, error: result.error.message }, status: :unprocessable_entity
      end
    end

    # webhook from leonardo
    def done
      Ai::Images::Done.call(params.permit!)
    end

    private

    def image_params
      params.require(:ai_image).permit(:occasion)
    end

    def verify_webhook_token
      provided_token = request.headers["Authorization"]
      expected_token = "Bearer #{Rails.application.credentials.dig(:leonardo, :webhook_token)}"

      if provided_token.nil? || !ActiveSupport::SecurityUtils.secure_compare(provided_token, expected_token)
        Rails.logger.error "Webhook authentication failed"
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
