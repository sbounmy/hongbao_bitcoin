module Ai
  module ImagesGpt
    class Create < ApplicationService
      def call(params:, user:)
        @params = params
        @user = user

        process_images
        @paper.save!
        @paper
      end

      private

      def process_images
        # todo
      end
    end
  end
end
