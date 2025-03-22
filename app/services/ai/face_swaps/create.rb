module Ai
  module FaceSwaps
    class Create < ApplicationService
      attr_reader :params, :user
      def call(params:, user:)
        @params = params
        @user = user

        create_record
        call_api
      end

      def create_record
        @face_swap = Ai::FaceSwap.create!(
          user:,
          prompt: "Swap the face of the person in the image with the face of the person in the image"
        ).process
      end

      def call_api
        Rails.logger.info("Calling API #{paper.image_front.inspect} #{params[:image].inspect}")
        Client::FaceSwap.new.swap_faces(
          files: {
            source_image: paper.image_front,
            face_image: params[:image]
          },
          webhook: "https://stephane.hongbaob.tc/ai/face_swap/done"
        ).tap do |response|
          @face_swap.update!(
            external_id: response.data.task_id,
          )
        end
      end

      def paper
        @paper ||= Paper.find(params[:paper_id])
      end
    end
  end
end
