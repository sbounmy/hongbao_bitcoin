require "open-uri"
require "net/http"

module Webhooks
  class FaceSwapController < ApplicationController
    skip_before_action :require_authentication, only: [ :webhook ]
    skip_before_action :verify_authenticity_token, only: [ :webhook ]

    def webhook
      Rails.logger.info "Webhook received: #{params.to_json}"

      task_id = params[:task_id]
      success = params[:success].to_i == 1
      result_image_url = params[:result_image]
      paper = Paper.find_by(task_id: task_id)
      face_swap_task = Ai::FaceSwap.find_by(external_id: task_id)
      return render json: { error: "Invalid webhook data" }, status: :bad_request unless task_id && result_image_url
      Rails.logger.info "Current user: #{current_user.inspect}"
        if success
          new_paper = Paper.new(
            name: "Face Swapped #{paper.name}",
            style: paper.style,
            active: true,
            public: false,
            user: face_swap_task.user,
            task_id: task_id
          )
          new_paper.image_back.attach(paper.image_back.blob) if paper.image_back.attached?

          downloaded_result_image = URI.parse(result_image_url).open
          new_paper.image_front.attach(
            io: downloaded_result_image,
            filename: "face_swapped_#{paper.id}.png",
            content_type: "image/png"
          )

          new_paper.save!
          Rails.logger.info "Face swap success! Image URL: #{result_image_url}"
          face_swap_task.update(status: "completed")

          Turbo::StreamsChannel.broadcast_update_to(
            "ai_generations_#{face_swap_task.user.id}",
            target: "ai_generations_#{face_swap_task.user.id}",
            partial: "hong_baos/new/steps/design/generated_designs",
            locals: { papers_by_user: face_swap_task.user.papers, user: face_swap_task.user }
          )
        else
          Rails.logger.error "Face swap failed for task_id: #{task_id}"
        end

      render json: { message: "Webhook processed successfully" }, status: :ok
    end
  end
end
