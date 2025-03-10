class FaceSwapProcessController < ApplicationController
  def index
  end


  def process_face_swap
    Rails.logger.info "Processing face swap for Paper ##{params[:paper_id]}"
    paper = Paper.find(params[:paper_id])
    face_to_swap = params[:image]
    image_url = paper.image_front

    Rails.logger.info "Starting face swap for Paper ##{paper.id}"

    response = FaceSwapService.swap_faces(
      image_url,
      face_to_swap,
      "https://steady-bonefish-smashing.ngrok-free.app/webhooks/face_swap"
    )

    if response && response["data"]["task_id"]
      Rails.logger.info "Face swap request sent. Current user: #{current_user.inspect}"
      paper.update(task_id: response["data"]["task_id"])
      face_swap_task = Ai::FaceSwap.new(
        external_id: response["data"]["task_id"],
        user: current_user,
        status: "processing",
        prompt: "Swap the face of the person in the image with the face of the person in the image"
      )
      face_swap_task.save!
      Rails.logger.info "Face swap request sent. Task ID: #{response["data"]["task_id"]}"
      render json: { status: "processing", task_id: response["data"]["task_id"], message: "Face swap initiated" }
    else
      Rails.logger.error "Face swap request failed: #{response}"
      render json: { error: "Face swap request failed" }, status: :unprocessable_entity
    end
  end
end
