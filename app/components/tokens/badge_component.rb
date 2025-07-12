# frozen_string_literal: true

module Tokens
  class BadgeComponent < ViewComponent::Base
    def initialize(user:, **options)
      raise ArgumentError, "user must be present" if user.nil?
      @user = user
      @options = options
      super
    end

    def quantity
      @quantity ||= user.tokens_sum
    end

    def class_name
      options[:class]
    end

    private

    attr_reader :user, :options
  end
end
