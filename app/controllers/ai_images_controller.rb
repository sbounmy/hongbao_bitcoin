class AiImagesController < ApplicationController
  def create
    result = Ai::Images::Create.call(image_params)
    if result.success?
      render json: { success: true, image: result.payload }
    else
      render json: { success: false, error: result.error.message }, status: :unprocessable_entity
    end
  end

  # webhook from leonardo
  def complete
    Ai::Images::Complete.call(image_params)
  end

  private

  def image_params
    params.require(:image).permit(:occasion)
  end
end
