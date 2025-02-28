module Webhooks
  class FaceSwapController < ApplicationController
    skip_before_action :require_authentication, only: [ :webhook ]
    skip_before_action :verify_authenticity_token, only: [ :webhook ]
    before_action :verify_webhook_token, only: [ :webhook ]

    def webhook
      Rails.logger.info "Webhook received: #{params.to_json}"

      task_id = params[:task_id]
      success = params[:success].to_i == 1
      result_image_url = params[:result_image]

      return render json: { error: "Invalid webhook data" }, status: :bad_request unless task_id && result_image_url

      # generation = Ai::Generation.find_by(task_id: task_id)
      generation = Ai::Generation.last

      if generation
        if success
          generation.update(result_image: result_image_url, status: "completed")
          Rails.logger.info "Face swap success! Image URL: #{result_image_url}"
        else
          generation.update(status: "failed")
          Rails.logger.error "Face swap failed for task_id: #{task_id}"
        end
      else
        Rails.logger.error "No matching generation found for task_id: #{task_id}"
        return render json: { error: "Task not found" }, status: :not_found
      end

      render json: { message: "Webhook processed successfully" }, status: :ok
    end

    def process_face_swap
      generation = Ai::Generation.last
      face_to_swap = generation.face_to_swap
      image_url = generation.generated_images.first

      Rails.logger.info "Starting face swap for Generation ##{generation.id}"

      response = FaceSwapService.swap_faces(
        image_url,
        face_to_swap,
        "https://steady-bonefish-smashing.ngrok-free.app/webhooks/face_swap"
      )

      if response && response["task_id"]
        generation.update(task_id: response["task_id"], status: "processing")
        Rails.logger.info "Face swap request sent. Task ID: #{response["task_id"]}"
        render json: { status: "processing", task_id: response["task_id"], message: "Face swap initiated" }
      else
        Rails.logger.error "Face swap request failed: #{response}"
        render json: { error: "Face swap request failed" }, status: :unprocessable_entity
      end
    end
  end
end
