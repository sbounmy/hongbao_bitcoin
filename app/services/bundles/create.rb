module Bundles
  class Create < ApplicationService
    def call(user:, params:)
      @user = user
      @params = params

      create_bundle
      create_chats
      create_papers
    end

    private

    def create_bundle
      @bundle = Bundle.create!(user: @user, **@params)
    end

    def create_chats
      @bundle.styles.each do |style|
        chat = Chat.create!(user: @user, bundle: @bundle, input_items: @bundle.input_items.where(input: [ @bundle.theme, style, @bundle.images.first ]))
        chat.messages.create!(
          user: @user,
          content: chat.input_items.map(&:prompt).compact_blank.join("\n"))
      end
    end

    def create_papers
      @bundle.chats.each do |chat|
        ProcessPaperJob.perform_later(chat.messages.first)
      end
    end
  end
end
