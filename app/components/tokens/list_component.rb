# frozen_string_literal: true

# Renders the list/table structure for token history.
module Tokens
  class ListComponent < ViewComponent::Base
    # Provides the collection to the ItemComponent using `with_collection`
    renders_many :items, Tokens::ItemComponent

    attr_reader :tokens

    # @param tokens [Enumerable] The collection of token transaction objects.
    def initialize(tokens:)
      @tokens = tokens

      # Prepare the items collection for rendering
      # Passes each token from @tokens to a new Tokens::ItemComponent instance.
      with_items(tokens)
    end

    # Helper method to check if there are any tokens to display.
    # Keeps logic out of the template.
    def empty_state?
      tokens.blank?
    end
  end
end
