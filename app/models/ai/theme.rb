module Ai
  class Theme < ApplicationRecord
    self.table_name = "themes"

    has_and_belongs_to_many :elements, class_name: "Ai::Element"

    validates :title, presence: true
    validates :elements, presence: true

    def self.ransackable_attributes(auth_object = nil)
      [ "created_at", "id", "title", "updated_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "elements" ]
    end
  end
end
