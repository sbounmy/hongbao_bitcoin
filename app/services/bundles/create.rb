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
          content: chat.input_items.map(&:prompt).compact_blank.join("\n"))
        Paper.create!(
          name: "Generated Paper #{SecureRandom.hex(4)}",
          active: true,
          public: false,
          user: chat.user,
          bundle: chat.bundle,
          message: message
        )
        ProcessPaperJob.perform_later(message.id, quality: @quality)
      end
    end

    def create_tokens
      @user.tokens.create(quantity: -@bundle.styles.count, description: "Bundle #{@bundle.id} tokens #{@bundle.styles.map(&:name).join(', ')}")
    end
  end
end
