module Ai
  class FaceSwapsController < BaseController
    skip_before_action :verify_webhook_token, only: [ :done ]

    def create
      response = Ai::FaceSwaps::Create.call(params: face_swap_params, user: current_user)

      if response.success?
        render json: { status: "processing", task_id: response.payload.external_id, message: "Face swap initiated" }
      else
        render json: { error: "Face swap request failed" }, status: :unprocessable_entity
      end
    end

    # webhook from face_swap
    def done
      Ai::FaceSwaps::Done.call(params.permit!)
    end

    private

    def face_swap_params
      params.require(:ai_face_swap).permit(:paper_id, :image)
    end
  end
end
