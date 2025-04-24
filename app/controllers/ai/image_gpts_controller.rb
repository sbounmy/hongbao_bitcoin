module Ai
  class ImageGptsController < ApplicationController
    def create
      result = Ai::ImageGpts::Create.call(params: image_params, user: current_user)
      if result.success?
        redirect_to root_path, notice: "Image generation queued!"
      else
        redirect_to root_path, alert: result.error.message
      end
    end

    private

    def image_params
      params.require(:ai_image_gpt).permit(:ai_theme_id, :image, ai_style_ids: [])
    end
  end
end
