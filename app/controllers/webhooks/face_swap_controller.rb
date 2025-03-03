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

      return render json: { error: "Invalid webhook data" }, status: :bad_request unless task_id && result_image_url

        if success
          new_paper = Paper.new(
            name: "Face Swapped #{paper.name}",
            style: paper.style,
            active: true,
            public: false,
            user: paper.user,
            task_id: task_id
          )
          new_paper.image_back.attach(paper.image_back.blob) if paper.image_back.attached?
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
          Rails.logger.info "Face swap success! Image URL: #{result_image_url}"

          # Clean up temporary files
          FileUtils.rm_f(result_temp_path)
          temp_file.close
          temp_file.unlink

        else
          Rails.logger.error "Face swap failed for task_id: #{task_id}"
        end

      render json: { message: "Webhook processed successfully" }, status: :ok
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

        paper.update(task_id: response["data"]["task_id"])
        Rails.logger.info "Face swap request sent. Task ID: #{response["data"]["task_id"]}"
        render json: { status: "processing", task_id: response["data"]["task_id"], message: "Face swap initiated" }
      else
        Rails.logger.error "Face swap request failed: #{response}"
        render json: { error: "Face swap request failed" }, status: :unprocessable_entity
      end
    end
  end
end
