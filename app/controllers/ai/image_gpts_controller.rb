module Ai
  class ImageGptsController < ApplicationController
    def create
      result = Ai::ImageGpts::Create.call(params: image_params, user: current_user)
      if result.success?
        render json: { success: true, image: result.payload }
      else
        render json: { success: false, error: result.error.message }, status: :unprocessable_entity
      end
    end


    private

    def image_params
      params.require(:ai_image_gpt).permit(:style_ids, :image)
    end
  end
end
