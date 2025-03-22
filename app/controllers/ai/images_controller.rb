module Ai
  class ImagesController < BaseController
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

    def webhook_token
      Rails.application.credentials.dig(:leonardo, :webhook_token)
    end
  end
end
