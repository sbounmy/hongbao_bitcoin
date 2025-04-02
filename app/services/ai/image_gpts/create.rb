module Ai
  module ImageGpts
    class Create < ApplicationService
      attr_reader :theme, :params, :user

      def call(params:, user:)
        @params = params
        @user = user

        success process_images
      end

      private

      def process_images
        styles.map do |style|
          # call chatgpt-4o to create images with style
          # RubyLLM.ask(
          #   model: 'gpt-4o',
          #   prompt: "1. #{style.text}\n2. #{theme.text}"
          #   with: {
          #     image: params[:image]
          #   }
          # )
          Paper.new(
            user:,
            ai_style_id: style.id,
            ai_theme_id: theme.id,
            public: false,
            name: "#{style.title} #{theme.title}"
          ).tap do |paper|
            paper.image_front.attach(params[:image])
            paper.image_back.attach(params[:image])
            paper.save!
          end
        end
      end

      def theme
        @theme ||= Ai::Theme.find(params[:ai_theme_id])
      end

      def styles
        @styles ||= Ai::Style.find(params[:ai_style_ids])
      end
    end
  end
end
