module Ai
  class Task < ApplicationRecord
    include AASM
    belongs_to :user
    belongs_to :source, polymorphic: true, optional: true

    validates :status, presence: true
    has_many_attached :images, dependent: :destroy
    has_one_attached :image, dependent: :destroy
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
