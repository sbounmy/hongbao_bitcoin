module Ai
  module FaceSwap
    class Create < ApplicationService
      attr_reader :params, :user
      def call(params:, user:)
        @params = params
        @user = user

        create_record
        call_api
        update_record
      end

      def create_record
        @face_swap = Ai::FaceSwap.create!(
          user:,
          prompt: "Swap the face of the person in the image with the face of the person in the image"
        ).process
      end

      def call_api
        FaceSwap.call(paper.image_front, params[:image])
      end

      def update_record
        @face_swap.update!(
          external_id: response["data"]["task_id"],
        )
      end

      def paper
        @paper ||= Paper.find(params[:paper_id])
      end
    end
  end
end
