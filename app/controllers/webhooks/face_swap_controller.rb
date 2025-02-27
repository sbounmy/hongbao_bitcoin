module Webhooks
class FaceSwapController < ApplicationController
  # skip_before_action :verify_authenticity_token


  def webhook
    generation = Ai::Generation.find(params[:generation_id])
    Rails.logger.info "webhook: #{params[:generation_id]}"
    Rails.logger.info "WEBHOOK GENERATION: #{generation}"
  end

  def get_generation
    generation = Ai::Generation.find(params[:generation_id])
    Rails.logger.info "get_generation: #{params[:generation_id]}"
    Rails.logger.info "GET GENERATION: #{generation}"
    generation
  end

  def process_face_swap
    generation = get_generation
    face_to_swap = generation.face_to_swap
    image_url = generation.generated_images.first
    swap_result = FaceSwapService.swap_faces(face_to_swap, image_url, "https://reliably-decent-oarfish.ngrok-free.app/webhooks/face_swap")
    Rails.logger.info "Face swap result: #{swap_result}"
    # if swap_result && swap_result["status"] == "success"
    #   generation.update!(image_urls: [ swap_result["result_url"] ])
    # end
  end
end
end
