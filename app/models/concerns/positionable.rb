module Positionable
  extend ActiveSupport::Concern

  included do
    scope :by_position, -> { order(:position) }
  end
end
