# frozen_string_literal: true

module Btcdex
  class BottomSheetComponent < ApplicationComponent
    def initialize(id:, user:)
      @id = id
      @user = user
    end

    private

    attr_reader :id, :user
  end
end
