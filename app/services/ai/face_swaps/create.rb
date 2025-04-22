module Ai
  module FaceSwaps
    class Create < ApplicationService
      attr_reader :params, :user
      def call(params:, user:)
        @params = params
        @user = user

        create_record
        call_api

        success @face_swap
      end

      def create_record
        @face_swap = Ai::FaceSwap.create!(
          user:,
          source: paper,
          prompt: "Swap the face of the person in the image with the face of the person in the image"
        ).tap &:process
      end

      def call_api
        Client::FaceSwap.new.swap_faces(
          source_image: paper.image_front,
          face_image: params[:image],
          webhook: Rails.application.routes.url_helpers.done_ai_face_swaps_url
        ).tap do |response|
          @face_swap.update!(
            external_id: response.task_id,
          )
        end
      end

      def paper
        @paper ||= Paper.find(params[:paper_id])
      end
    end
  end
end
