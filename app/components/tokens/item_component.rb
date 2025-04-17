# frozen_string_literal: true

# Represents a single row (transaction) in the token history list.
module Tokens
  class ItemComponent < ViewComponent::Base
    attr_reader :token

    def initialize(token:)
      @token = token
    end

    def token_label
      token.quantity > 0 ? "Purchase" : "Used"
    end
  end
end
