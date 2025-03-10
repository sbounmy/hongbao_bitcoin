module Ai
  class Task < ApplicationRecord
    belongs_to :user
    validates :external_id, presence: true, uniqueness: true
    validates :status, presence: true
  end
end
