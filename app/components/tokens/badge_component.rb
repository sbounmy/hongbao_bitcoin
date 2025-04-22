# frozen_string_literal: true

module Tokens
  class BadgeComponent < ViewComponent::Base
    def initialize(user:)
      raise ArgumentError, "user must be present" if user.nil?
      @user = user
      super
    end

    def quantity
      @quantity ||= user.tokens_sum
    end

    private

    attr_reader :user
  end
end
