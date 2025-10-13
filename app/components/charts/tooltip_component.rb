# frozen_string_literal: true

module Charts
  class TooltipComponent < ApplicationComponent
    def initialize(date:, points:, hong_baos: nil)
      @date = date
      @points = points
      @hong_baos = hong_baos
    end

    private

    attr_reader :date, :points, :hong_baos

    def has_hong_baos?
      hong_baos.present? && hong_baos.any?
    end
  end
end
