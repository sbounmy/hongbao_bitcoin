module Bundles
  class Create < ApplicationService
    def call(user:, params:)
      @user = user
      @params = params

      create_bundle
    end

    private

    def create_bundle
      @bundle = Bundle.create!(user: @user, **@params)
      @bundle.styles.each do |style|
        Chat.create!(user: @user, bundle: @bundle, input_item_ids: [ @bundle.theme.id, style.id, @bundle.images.first.id ])
      end
    end
  end
end
