# frozen_string_literal: true

module Papers
  class RecentPhotoComponent < ApplicationComponent
    with_collection_parameter :input_item

    def initialize(input_item:)
      @input_item = input_item
    end

    private

    attr_reader :input_item
  end
end
