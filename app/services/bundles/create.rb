module Bundles
  class Create < ApplicationService
    def call(user:, params:)
      @user = user
      @params = params

      create_bundle
      create_chats
    end

    private

    def create_bundle
      @bundle = Bundle.create!(user: @user, **@params)
    end

    def create_chats
      @bundle.styles.each do |style|
        Chat.create!(user: @user, bundle: @bundle, style: style)
      end
    end

    def create_papers
      @bundle.chats.each do |chat|
        ProcessPaperJob.perform_later(chat)
      end
    end
  end
end
