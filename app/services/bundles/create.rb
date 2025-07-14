module Bundles
  class Create < ApplicationService
    def call(user:, params:)
      @user = user
      @params = params
      @quality = @params.delete(:quality) || ENV.fetch("GPT_IMAGE_QUALITY", "high")
      create_bundle
      create_chats
      create_tokens
    end

    private

    def create_bundle
      @bundle = Bundle.create!(user: @user, **@params)
    end

    def create_chats
      @bundle.styles.each do |style|
        chat = Chat.create!(user: @user, bundle: @bundle, input_items: @bundle.input_items.where(input: [ @bundle.theme, style, @bundle.images.first ]))
        message = chat.messages.create!(
          user: @user,
          content: chat.input_items.map(&:prompt).compact_blank.join("\n")
        )

        paper = Paper.create!(
          name: "#{style.name} #{@bundle.theme.name}",
          active: true,
          public: false,
          user: chat.user,
          bundle: chat.bundle,
          input_ids: chat.input_items.map(&:input_id),
          input_item_ids: chat.input_items.map(&:id),
          message: message
        )
        ProcessPaperJob.perform_later(message.id, quality: @quality)

        Rails.logger.info("Message created #{message.id} for paper #{paper.id}")
      end
    end

    def create_tokens
      @user.tokens.create(quantity: -@bundle.styles.count, description: "Bundle #{@bundle.id} tokens #{@bundle.styles.map(&:name).join(', ')}")
    end
  end
end
