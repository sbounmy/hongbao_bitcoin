# frozen_string_literal: true

# Renders the list/table structure for token history.
module Tokens
  class ListComponent < ViewComponent::Base
    # Provides the collection to the ItemComponent using `with_collection`
    renders_many :tokens, Tokens::ItemComponent

    # @param tokens [Enumerable] The collection of token transaction objects.
    def initialize(tokens:)
      with_tokens(tokens.map { |token| { token: } })
    end

    # Helper method to check if there are any tokens to display.
    # Keeps logic out of the template.
    def empty_state?
      tokens.blank?
    end
  end
end
