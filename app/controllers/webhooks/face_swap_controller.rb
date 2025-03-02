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

      #       # Get the paper_id from params and ensure it's not blank
      #       paper_id = params[:paper_id].presence

      #       unless paper_id
      #         Rails.logger.error "No paper_id provided in params"
      #         return render json: { error: "Paper ID is required" }, status: :bad_request
      #       end

      # Rails.logger.info "Paper ID: #{paper_id}"
      paper = Paper.last

      return render json: { error: "Invalid webhook data" }, status: :bad_request unless task_id && result_image_url

      # generation = Ai::Generation.find_by(task_id: task_id)
      generation = Ai::Generation.last

      if generation
        if success
          new_paper = Paper.new(
            name: "Face Swapped #{paper.name}",
            style: paper.style,
            active: true,
            public: false,
            user: paper.user
          )
          # Attach the image_back after creation if the original paper has one
          new_paper.image_back.attach(paper.image_back.blob) if paper.image_back.attached?
          # Download and verify the source image using Net::HTTP
          uri = URI.parse(result_image_url)
          response = Net::HTTP.get_response(uri)

          # Create a temporary file to store the downloaded image
          temp_file = Tempfile.new([ "downloaded_image", ".png" ])
          temp_file.binmode
          temp_file.write(response.body)
          temp_file.rewind

          result_image = ImageProcessing::Vips
          .source(temp_file)
          .convert("png")
          .call
          temp_dir = Rails.root.join("tmp", "image_processing")
          FileUtils.mkdir_p(temp_dir)

          result_temp_path = temp_dir.join("result_image.png")
          FileUtils.cp(result_image.path, result_temp_path)

          # Download and attach the face-swapped image
          new_paper.image_front.attach(
            io: File.open(result_temp_path),
            filename: "face_swapped_#{paper.id}.png",
            content_type: "image/png"
          )

          new_paper.save!
          generation.update(result_image: result_image_url, status: "completed")
          Rails.logger.info "Face swap success! Image URL: #{result_image_url}"

          # Clean up temporary files
          FileUtils.rm_f(result_temp_path)
          temp_file.close
          temp_file.unlink

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
      paper = Paper.last
      face_to_swap = generation.face_to_swap
      image_url = paper.image_front

      Rails.logger.info "Starting face swap for Paper ##{paper.id}"

      response = FaceSwapService.swap_faces(
        image_url,
        face_to_swap,
        "https://steady-bonefish-smashing.ngrok-free.app/webhooks/face_swap"
      )

      if response && response["task_id"]

        paper.update(task_id: response["task_id"])
        Rails.logger.info "Face swap request sent. Task ID: #{response["task_id"]}"
        render json: { status: "processing", task_id: response["task_id"], message: "Face swap initiated" }
      else
        Rails.logger.error "Face swap request failed: #{response}"
        render json: { error: "Face swap request failed" }, status: :unprocessable_entity
      end
    end
  end
end
