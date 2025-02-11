module Ai
  class Element < ApplicationRecord
    self.table_name = "elements"

    validates :element_id, presence: true, uniqueness: true
    validates :title, presence: true
    validates :weight, presence: true

    def self.ransackable_attributes(auth_object = nil)
      [ "created_at", "element_id", "id", "title", "updated_at", "weight" ]
    end

    def self.ransackable_associations(auth_object = nil)
      []  # Remove themes from ransackable associations
    end
  end
end
