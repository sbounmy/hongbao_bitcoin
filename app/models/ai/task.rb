module Ai
  class Task < ApplicationRecord
    include AASM
    belongs_to :user
    validates :status, presence: true
    has_many_attached :images, dependent: :destroy

    aasm column: :status do
      state :created, initial: true
      state :processing
      state :completed
      state :failed

      event :process do
        transitions from: :created, to: :processing
      end

      event :complete do
        transitions from: :processing, to: :completed
      end

      event :fail do
        transitions from: :pending, to: :failed
      end
    end
  end
end
