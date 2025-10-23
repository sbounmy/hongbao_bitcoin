# frozen_string_literal: true

module Tokens
  class BadgeComponent < ViewComponent::Base
    def initialize(user:, link: true, **options)
      raise ArgumentError, "user must be present" if user.nil?
      @user = user
      @link = link
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

    attr_reader :user, :options, :link
  end
end
