module Ai
  class ImageGptsController < ApplicationController
    def create
      result = Ai::ImageGpts::Create.call!(params: image_params, user: current_user)
      if result.success?
        # This should be done through turbo frame

        render json: { success: true, image: result.payload }
      else
        render json: { success: false, error: result.error.message }, status: :unprocessable_entity
      end
    end


    private

    def image_params
      params.require(:ai_image_gpt).permit(:ai_theme_id, :image, ai_style_ids: [])
    end
  end
end
