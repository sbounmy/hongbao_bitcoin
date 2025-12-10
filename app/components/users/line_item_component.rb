# frozen_string_literal: true

module Users
  class LineItemComponent < ApplicationComponent
    with_collection_parameter :user
    attr_reader :user

    def initialize(user:)
      @user = user
      super
    end

    private

    def avatar_url
      url_for(user.avatar) if user.avatar.attached?
    end

    def formatted_followers_count
      # NOTE: This assumes a `followers_count` attribute on the User model.
      # A more robust solution might use `number_to_human`.
      count = user.followers_count || 0
      if count >= 1000
        "#{(count / 1000.0).round(1)}K"
      else
        count.to_s
      end
    end

    def handle
      # NOTE: Assumes a `handle` attribute on the User model.
      user.handle || user.firstname.parameterize
    end
  end
end
