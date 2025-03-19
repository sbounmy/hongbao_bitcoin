module Ai
  class FaceSwapController < BaseController
    def create
      response = Ai::FaceSwap::Create.call(params: face_swap_params, user: current_user)

      if response.success?
        render json: { status: "processing", task_id: response["data"]["task_id"], message: "Face swap initiated" }
      else
        render json: { error: "Face swap request failed" }, status: :unprocessable_entity
      end
    end

    # webhook from face_swap
    def done
      Ai::FaceSwap::Done.call(params.permit!)
    end

    private

    def face_swap_params
      params.require(:face_swap).permit(:paper_id, :image)
    end

    def webhook_token
      Rails.application.credentials.dig(:faceswap, :webhook_token)
    end
  end
end
