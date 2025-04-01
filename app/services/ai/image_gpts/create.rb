module Ai
  module ImageGpts
    class Create < ApplicationService
      attr_reader :theme, :params, :user

      def call(params:, user:)
        @params = params
        @user = user

        process_images
      end

      private

      def process_images
        styles.each do |style|
          # call chatgpt-4o to create images with style
          # RubyLLM.ask(
          #   model: 'gpt-4o',
          #   prompt: "1. #{style.text}\n2. #{theme.text}"
          #   with: {
          #     image: params[:image]
          #   }
          # )
          Paper.create!(
            user:,
            ai_style: style,
            ai_theme: theme,
          ).tap do |paper|
            paper.image_front.attach(
              io: params[:image],
              filename: "#{style.title.parameterize(separator: '_')}.jpg"
            )
          end
        end
      end

      def theme
        @theme ||= Ai::Theme.find(params[:ai_theme_id])
      end

      def styles
        @styles ||= Ai::Style.where(id: params[:ai_style_ids])
      end
    end
  end
end
