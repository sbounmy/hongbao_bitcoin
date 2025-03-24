module Ai
  module FaceSwaps
    class Done < ApplicationService
      def call(params)
        @params = params
        @face_swap = ::Ai::FaceSwap.find_by!(external_id: params[:task_id])

        return failure(StandardError.new("Face swap failed")) unless params[:success] == 1

        ActiveRecord::Base.transaction do
          update_task
          create_child_paper
          mark_face_swap_as_done
        end

        # broadcast_result
        success(@face_swap)
      rescue ActiveRecord::RecordNotFound => e
        failure(e, { task_id: params[:task_id] })
      rescue StandardError => e
        failure(e, { params: params })
      end

      private

      def update_task
        @face_swap.update!(
          response_image_url: @params[:result_image]
        )
      end

      def create_child_paper
        @child_paper = @face_swap.source.children.build(
          name: "#{@face_swap.source.name} (Face Swap)",
          user: @face_swap.source.user,
        )

        # Attach the new face-swapped image
        attach_result_image
        attach_back_image
        @child_paper.save!
      end

      def attach_result_image
        image_url = @params[:result_image]
        downloaded_image = URI.open(image_url)
        @child_paper.image_front.attach(
          io: downloaded_image,
          filename: "face_swap_#{@params[:task_id]}.webp"
        )
      end

      def attach_back_image
        Rails.logger.info("Attaching back image for source paper: #{@face_swap.source.id}")

        if @face_swap.source.image_back.attached?
          Rails.logger.info("Source paper has image_back attached")
          @child_paper.image_back.attach(@face_swap.source.image_back.blob)
        else
          Rails.logger.error("Source paper does not have image_back attached")
          raise StandardError.new("Source paper does not have image_back attached")
        end
      end

      def mark_face_swap_as_done
        @face_swap.complete!
      end

      def broadcast_result
        Turbo::StreamsChannel.broadcast_replace_to(
          "face_swap_#{@face_swap.external_id}",
          target: "face_swap_result",
          partial: "papers/paper",
          locals: { paper: @child_paper }
        )
      end
    end
  end
end
